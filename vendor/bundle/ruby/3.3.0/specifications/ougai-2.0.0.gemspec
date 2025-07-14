# -*- encoding: utf-8 -*-
# stub: ougai 2.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "ougai".freeze
  s.version = "2.0.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Toshimitsu Takahashi".freeze]
  s.date = "2021-02-21"
  s.description = "    A structured logging system is capable of handling a message, custom data or an exception easily.\n    It has JSON formatters compatible with Bunyan or pino for Node.js and human readable formatter with Amazing Print for console.\n".freeze
  s.email = ["toshi@tilfin.com".freeze]
  s.homepage = "https://github.com/tilfin/ougai".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5.0".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "JSON logger compatible with node-bunyan or pino is capable of handling structured data easily.".freeze

  s.installed_by_version = "3.6.3".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<oj>.freeze, ["~> 3.10".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 2.1.4".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 13.0.1".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 3.9.0".freeze])
end
