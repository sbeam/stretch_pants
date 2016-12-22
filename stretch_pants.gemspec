Gem::Specification.new do |s|
   s.name        = 'stretch_pants'
   s.version     = '0.0.1'
   s.date        = '2016-12-20'
   s.summary     = "Chainable ElasticRecord"
   s.has_rdoc    = false
  # s.homepage    = "http://github.com/#{login}/#{name}"
   s.authors     = ["Sam Beam"]
   s.email       = 'sbeam@syxyz.net'
   s.files       = ["lib/stretch_pants.rb"]
   s.license     = 'MIT'
   s.files       += Dir.glob("lib/**/*")
   s.files       += Dir.glob("spec/**/*")

   s.add_development_dependency('rspec')
   s.add_development_dependency('pry')
   s.add_development_dependency('pry-byebug')
   s.add_dependency('elasticsearch-client')
   s.add_dependency('elasticsearch-transport')
   s.add_dependency('hashie')
   s.add_dependency('activesupport')

  s.description       = <<-desc
  chain ElasticSearch queries, filters and scopes together
  desc
end
