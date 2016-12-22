require 'spec_helper'

describe StretchPants::Search do

  class Person < StretchPants::Search::Base; end

  let (:es_response) { { hits: { hits: [ { :'_source' => { name: 'Tywin Lannister' } } ] } } }   # testing an ugly interface is ugly

  it 'should query the correct index based on the model name' do
    Elasticsearch::Transport::Client.any_instance.should_receive(:search).with(hash_including(index: "person_#{StretchPants.configuration.index_env}")).and_return(es_response)
    Person.filter(:house => 'Lannister').to_a
  end

  describe '.find' do

    it 'queries ES with match query' do
      query = ->(index, body) { body[:body][:query].should eql({ match: { _id: 777 } }) }
      Elasticsearch::Transport::Client.any_instance.should_receive(:search, &query).and_return(es_response)
      Person.find(777)
    end

    it 'returns first item from results' do
      Elasticsearch::Transport::Client.any_instance.stub(search: es_response)
      Person.find(123).should == { 'name' => 'Tywin Lannister' }
    end

  end

  describe '.limit' do
    it 'adds the size param to the query' do
      query = ->(index, body) { body[:body][:size].should eql 123 }
      Elasticsearch::Transport::Client.any_instance.should_receive(:search, &query).and_return(es_response)
      Person.limit(123).to_a
    end
  end

  describe '.sort' do
    it 'adds the sort param to the query' do
      query = ->(index, body) { body[:body][:sort].should eql([:birthdate => :desc]) }
      Elasticsearch::Transport::Client.any_instance.should_receive(:search, &query).and_return(es_response)
      Person.filter(:house => 'Lannister').sort(:birthdate => :desc).to_a
    end
  end

  describe '.filter' do

    it 'queries ES with filter terms' do
      filter = ->(index, body) { body[:body][:filter][:and].should include({:term=>{:house=>"Lannister"}}) }
      Elasticsearch::Transport::Client.any_instance.should_receive(:search, &filter).and_return(es_response)
      Person.filter(house: 'Lannister').to_a
    end

    it 'adds multiple fields to individual term filters' do
      filter = ->(index, body) { body[:body][:filter][:and].should include(term: {:parent=>"Cersei"}) }
      Elasticsearch::Transport::Client.any_instance.should_receive(:search, &filter).and_return(es_response)
      Person.filter(house: 'Lannister', parent: 'Cersei').to_a
    end

    it 'allows multiple filters with the same key' do
      filter = ->(index, body) do
        body[:body][:filter][:and].should include(term: {:parent=>"Cersei"})
        body[:body][:filter][:and].should include(term: {:parent=>"Jaime"})
      end
      Elasticsearch::Transport::Client.any_instance.should_receive(:search, &filter).and_return(es_response)
      Person.filter(house: 'Lannister', parent: 'Cersei').filter(parent: "Jaime").to_a
    end

    it 'filters on other named params' do
      Elasticsearch::Transport::Client.any_instance.stub(search: es_response)
      Person.filter(house: 'Lannister').to_a.should == [{ 'name' => 'Tywin Lannister' }]
    end

    it 'uses a `in` filter if arg is an array' do
      filter = ->(index, body) { body[:body][:filter][:and].should include(in: {:houses =>["Lannister","Baratheon"]}) }
      Elasticsearch::Transport::Client.any_instance.should_receive(:search, &filter).and_return(es_response)
      Person.filter(houses: ['Lannister', 'Baratheon']).to_a
    end
    #
    # @Cheap_LED_tvs = Product.limit(3).on_site(@category).in_categories(["led"]).sort(rating: 'desc').filter(:range, field: "msrp", lt: 1000)
  end

  describe '.range' do
    it 'queries ES with a range filter' do
      filter = ->(index, body) { body[:body][:filter][:and].should include({:range=>{:age=>{gte:100}}}) }
      Elasticsearch::Transport::Client.any_instance.should_receive(:search, &filter).and_return(es_response)
      Person.filter(house: 'Lannister').range(:age, { gte: 100 }).to_a
    end
  end

  describe '.exists' do
    it 'queries ES with a exists filter' do
      filter = ->(index, body) { body[:body][:filter][:and].should include({:exists=>{:field=>:mode_of_death}}) }
      Elasticsearch::Transport::Client.any_instance.should_receive(:search, &filter).and_return(es_response)
      Person.filter(house: 'Lannister').exists(:mode_of_death).to_a
    end
  end

  describe '.missing' do
    it 'queries ES with a missing filter' do
      filter = ->(index, body) { body[:body][:filter][:and].should include({:missing=>{:field=>:mode_of_death}}) }
      Elasticsearch::Transport::Client.any_instance.should_receive(:search, &filter).and_return(es_response)
      Person.filter(house: 'Lannister').missing(:mode_of_death).to_a
    end
  end

  describe '.raw_terms' do
    it 'are passed directly into filter' do
      query = ->(index, body) { body[:body][:filter][:and].should include(:term=>:special_raw_terms) }
      Elasticsearch::Transport::Client.any_instance.should_receive(:search, &query).and_return(es_response)
      Person.filter(house: 'Lannister').raw_terms(:term => :special_raw_terms).to_a
    end
  end

  describe '.query' do
    it 'directly passes in a top-level query' do
      query = ->(index, body) { body[:body][:query].should == { :fuzzy => { :height => 5.0 } } }
      Elasticsearch::Transport::Client.any_instance.should_receive(:search, &query).and_return(es_response)
      Person.query(fuzzy: { height: 5.0 }).to_a
    end
  end

  describe '.including' do
    # this including thing is a hack, it probably should just be included in the index and not exist at all here.
    it 'tacks on related associations with find queries' do
      resp_with_heir = es_response
      resp_with_heir[:hits][:hits][0][:_source][:heir_id] = '888'           # add the property to the fake result

      Elasticsearch::Transport::Client.any_instance.stub(:search).and_return(resp_with_heir)
      Person.should_receive(:find).with('888').and_return({ name: 'Tyrion Lannister'})

      res = Person.filter(house: 'Lannister').including(:heir => :person).first
      res.heir.name.should == 'Tyrion Lannister'
    end

  end

  describe 'chained scopes' do

    it 'accumulate query setup params' do
      query = ->(index, body) {
        body[:body][:sort].should eql([:birthdate => :desc])
        body[:body][:size].should eql 11
      }
      Elasticsearch::Transport::Client.any_instance.should_receive(:search, &query).and_return(es_response)
      Person.sort(:birthdate => :desc).limit(11).to_a
    end

    it 'adds additional filters when chaining on a call to `filter`' do
      query = ->(index, body) { body[:body][:filter][:and].should eql([{:term=>{:house => "Targaryen"}}, {:term=>{:name => "Aegon"}}]) }
      Elasticsearch::Transport::Client.any_instance.should_receive(:search, &query).and_return(es_response)
      Person.filter(house: "Targaryen").filter(:term, name: "Aegon").first
    end

    it 'chains custom scopes like any other' do

      class Person
        scoped do
          def is_snow; filter(:surname => ['Snow']); end
          def on_wall; filter(:status => 'Nights Watch'); end
        end
      end

      query = ->(index, body) do
        body[:body][:filter][:and].should eql([{:term=>{:status=>"Nights Watch"}},
                                              {:term=>{:house => 'Baratheon'}},
                                              {:in=>{:surname => ["Snow"]}}])
      end
      Elasticsearch::Transport::Client.any_instance.should_receive(:search, &query).and_return(es_response)
      Person.on_wall.filter(:house => 'Baratheon').limit(3).is_snow.sort(:birthday).to_a
    end
  end


  describe StretchPants::Search::RangeFilter do
    it "is capable of converting itself to a hash" do
      StretchPants::Search::RangeFilter.new(field: "msrp", lte: 500).to_h[:range].class.should == Hash
    end

    it "creates a range filter" do
      query = ->(index, body) { body[:body][:filter][:and].should include({:range=>{:age => {:gte => 100}}}) }
      Elasticsearch::Transport::Client.any_instance.should_receive(:search, &query).and_return(es_response)
      Person.filter(:house => 'Targaryen').filter(:range, :age => {:gte => 100}).map(&:name)
    end
  end

  describe StretchPants::Search::Query do

    let(:query) { StretchPants::Search::Query.new("foo_index", {query: {match_all: {}}}, nil) }

    describe "lazy evaluation" do
      it "does not evaluate itself until call is invoked" do
        StretchPants::Search::Query.any_instance.should_not_receive(:call)
        Person.filter(:term, name: "samsung")
      end

      it "evaluates itself when attempting to iterate over the results" do
        StretchPants::Search::Query.any_instance.should_receive(:call).and_return(%w{foo bar baz})
        Person.filter(:term, name: "samsung").each do |product|
          nil # no-op
        end
      end

      it "evaluates itself when attempting to inspect the query (as in on the console)" do
        StretchPants::Search::Query.any_instance.should_receive(:call).and_return(%w{foo bar baz})
        Person.filter(:term, name: "samsung").inspect
      end

      it "raises an exception when attempting to filter by a non-existent filter" do
        expect { query.filter(:blargh, name: "samsung") }.to raise_exception
      end

      it "support multiple chaining" do
        query = ->(index, body) { body[:body][:filter][:and].should include(:term=>{:tagline => "A Lannister always spays his pets"}) }
        Elasticsearch::Transport::Client.any_instance.should_receive(:search, &query).and_return(es_response)
        Person.filter(rank: "King").filter(:term, tagline: "A Lannister always spays his pets").to_a
      end
    end

    describe "memoization" do
      it "only invokes the query once while it remains the same" do
        query = ->(index, body) { body[:body][:filter][:and].should include(:term=>{:tagline => "A Lannister always spays his pets"}) }
        Elasticsearch::Transport::Client.any_instance.should_receive(:search, &query).once.and_return(es_response)
        q = Person.limit(10).filter(:term, tagline: "A Lannister always spays his pets")
        q.map(&:house)
        q.map(&:name)
      end

      it "invokes the query again if filters change" do
        query = ->(index, body) { body[:body][:filter][:and].should include(:term=>{:tagline => "A Lannister always spays his pets"}) }
        query.should_receive(:call).twice # since this same object will be used by any instance, we need to install our rspec antenna here
        Elasticsearch::Transport::Client.any_instance.stub(:search, &query).and_return(es_response)
        q = Person.limit(10).filter(:term, tagline: "A Lannister always spays his pets")
        q.map(&:house)
        q.filter(:title => 'King').map(&:name)
      end
    end
  end
end
