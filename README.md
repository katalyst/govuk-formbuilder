# Katalyst::GOVUK::Formbuilder

Repacking of [GOV.UK Frontend](https://frontend.design-system.service.gov.uk) and
[GOV.UK form components](https://govuk-form-builder.netlify.app) for use in Katalyst projects.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "katalyst-govuk-formbuilder"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install katalyst-govuk-formbuilder

## Usage

Add the stylesheet to your default layout:

```erb
<%= stylesheet_link_tag "katalyst/govuk/formbuilder" %>
```

Some GOVUK components require javascript enhancements 
(see [GOVUK docs](https://frontend.design-system.service.gov.uk/get-started/#5-get-the-javascript-working)).

You can use the provided helper to load the formbuilder esm from importmaps and enhance your form:

```erb
<%= form_with ... %>
<%= govuk_formbuilder_init %>
```

You'll need to include the helper to make this method available, which you can add to your `ApplicationController`:

```ruby
helper Katalyst::GOVUK::Formbuilder::Frontend
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/katalyst/govuk-formbuilder.

## Release

Tag the release version and push to CI.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
