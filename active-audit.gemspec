Gem::Specification.new do |s|
  s.name        = 'active-audit'
  s.version     = "0.2.4"
  s.platform    = Gem::Platform::RUBY
  s.date        = '2016-07-16'
  s.summary     = "ORM extension to track model changes."
  s.description = "ORM extension to track model changes. It also support keeping record of who made the changes and why."
  s.authors     = ["Tariq Abughofa"]
  s.email       = 'mhdtariqabughofa@gmail.com'
  s.files = Dir["lib/**/*"]
  s.add_dependency 'rails-observers', '~> 0.1.2'
  s.add_dependency 'virtus', '~>1.0'

  s.homepage    = 'http://rubygems.org/gems/active-audit'
  s.license     = 'MIT'
end
