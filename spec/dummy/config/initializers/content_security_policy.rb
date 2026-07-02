# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# A strict, nonce-based Content Security Policy for the dummy app. This exists
# so we can prove the form builder's javascript (govuk_formbuilder_init, the
# importmap tags, hotwire_combobox, trix) works under a locked-down CSP.
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.base_uri    :self
    policy.font_src    :self
    policy.img_src     :self, :data, :blob
    policy.object_src  :none
    policy.connect_src :self
    policy.form_action :self
    policy.frame_ancestors :self

    # Strict on scripts (the XSS vector). Every script we emit is nonced, and
    # `strict-dynamic` trusts scripts loaded by an already-trusted script, so the
    # importmap and everything it imports runs.
    policy.script_src :self, :strict_dynamic

    # Turbo (progress bar) and Trix inject their own <style> elements at runtime.
    # Styles cannot execute script, so inline styles are permitted here.
    policy.style_src :self, :unsafe_inline
  end

  # Generate a fresh nonce per request; applied to script tags (and auto-added
  # to javascript/stylesheet helpers via nonce_auto).
  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]
  config.content_security_policy_nonce_auto = true
end
