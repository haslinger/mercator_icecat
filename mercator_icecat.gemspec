$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "mercator_icecat/version"

Gem::Specification.new do |s|
  s.name        = "mercator_icecat"
  s.version     = MercatorIcecat::VERSION
  s.authors     = ["Stefan Haslinger"]
  s.email       = ["stefan.haslinger@informatom.com"]
  s.homepage    = "http://mercator.informatom.com"
  s.summary     = "MercatorIcecat provides an Icecat Importer for the Mesonic Guided Selling Application."
  s.description = "MercatorIcecat interfaces between Mercator and the Icecat Product Catalog in the realm of product properties, attributes, data sheets, images and product relations."
  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.0.3"
  s.add_dependency "saxerator"
end