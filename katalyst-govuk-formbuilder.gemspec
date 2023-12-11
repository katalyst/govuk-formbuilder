# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "katalyst-govuk-formbuilder"
  spec.version       = "1.7.1"
  spec.authors       = ["Katalyst Interactive"]
  spec.email         = ["developers@katalyst.com.au"]

  spec.summary       = "Repackaging of UK.GOV forms for Rails 7 asset pipeline"
  spec.description   = "UK.GOV form builder ready for use in Katalyst projects"
  spec.homepage      = "https://github.com/katalyst/govuk-formbuilder"
  spec.license       = "MIT"

  spec.files = Dir["app/assets/**/*", "{config,lib,vendor}/**/*", "CHANGELOG.md", "LICENSE.txt", "README.md"]
  spec.require_paths = %w[lib]
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.add_dependency "govuk_design_system_formbuilder"
end
