# frozen_string_literal: true
require_relative "lib/ermir/version"

Gem::Specification.new do |spec|
  spec.name = "ermir"
  spec.version = Ermir::VERSION
  spec.authors = "hakivvi"
  spec.email = "hakivvi@gmail.com"

  spec.summary = "Ermir is an Evil RMI Registry."
  spec.description = "Ermir is an Evil/Rogue RMI Registry, it exploits unsecure deserialization on any Java code calling standard RMI methods on it (list()/lookup()/bind()/rebind()/unbind())."
  spec.homepage = "https://github.com/hakivvi/ermir"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "bin"
  spec.executables << spec.name.downcase << "gadgetmarshal"
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency 'slop', '~> 4.9.2'
  spec.add_dependency 'colorize', '~> 0.8.1'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
