# Katalyst::GOVUK::Formbuilder

Repacking of [GOV.UK Frontend](https://frontend.design-system.service.gov.uk) and
[GOV.UK form components](https://govuk-form-builder.netlify.app) for use in Katalyst projects.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'katalyst-govuk-formbuilder'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install katalyst-govuk-formbuilder

## Usage

Add the stylesheet to your default layout:

```erbruby
<%= stylesheet_link_tag "katalyst/govuk/formbuilder" %>
```

You will also need GOVUK's design system javascript, which you can import via npm or importmaps. Please ensure that
your javascript version matches the version packaged with this gem.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/katalyst/govuk-formbuilder.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
