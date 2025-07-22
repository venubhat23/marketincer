# -*- encoding: utf-8 -*-
# stub: brevo-ruby 1.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "brevo-ruby".freeze
  s.version = "1.0.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Brevo Developers".freeze]
  s.date = "2023-06-06"
  s.description = "Official Brevo provided RESTFul API V3 ruby library".freeze
  s.email = ["contact@brevo.com".freeze]
  s.homepage = "https://www.brevo.com/".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9".freeze)
  s.rubygems_version = "3.3.11".freeze
  s.summary = "Brevo API V3 Ruby Gem".freeze

  s.installed_by_version = "3.6.3".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<typhoeus>.freeze, ["~> 1.0".freeze, ">= 1.0.1".freeze])
  s.add_runtime_dependency(%q<json>.freeze, ["~> 2.1".freeze, ">= 2.1.0".freeze])
  s.add_runtime_dependency(%q<addressable>.freeze, ["~> 2.3".freeze, ">= 2.3.0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.6".freeze, ">= 3.6.0".freeze])
  s.add_development_dependency(%q<vcr>.freeze, ["~> 3.0".freeze, ">= 3.0.1".freeze])
  s.add_development_dependency(%q<webmock>.freeze, ["~> 1.24".freeze, ">= 1.24.3".freeze])
  s.add_development_dependency(%q<autotest>.freeze, ["~> 4.4".freeze, ">= 4.4.6".freeze])
  s.add_development_dependency(%q<autotest-rails-pure>.freeze, ["~> 4.1".freeze, ">= 4.1.2".freeze])
  s.add_development_dependency(%q<autotest-growl>.freeze, ["~> 0.2".freeze, ">= 0.2.16".freeze])
  s.add_development_dependency(%q<autotest-fsevent>.freeze, ["~> 0.2".freeze, ">= 0.2.12".freeze])
end
