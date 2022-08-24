
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "katalyst/govuk/formbuilder/version"

Gem::Specification.new do |spec|
  spec.name          = "katalyst-govuk-formbuilder"
  spec.version       = Katalyst::GOVUK::Formbuilder::VERSION
  spec.authors       = ["Katalyst Interactive"]
  spec.email         = ["developers@katalyst.com.au"]

  spec.summary       = %q{Repackaging of UK.GOV forms for Rails 7 asset pipeline}
  spec.description   = %q{UK.GOV form builder ready for use in Katalyst projects}
  spec.homepage      = "https://github.com/katalyst/govuk-formbuilder"
  spec.license       = "MIT"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage

  spec.files = Dir["lib/**/*", "CHANGELOG.md", "LICENSE.txt", "README.md"]
  spec.require_paths = %w[lib]

  spec.add_dependency "govuk_design_system_formbuilder"
end
