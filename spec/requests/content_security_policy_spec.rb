# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Content Security Policy" do
  before { get new_profile_path }

  let(:csp) { response.headers["Content-Security-Policy"] }

  it "locks scripts down with strict-dynamic and a nonce" do
    expect(csp).to include("'strict-dynamic'").and include("'nonce-")
  end

  it "restricts everything to self by default with no external hosts" do
    expect(csp).to include("default-src 'self'").and include("object-src 'none'")
  end

  it "nonces the emitted script tags" do
    nonce = csp[/'nonce-([^']+)'/, 1]
    expect(response.body).to include(%(nonce="#{nonce}"))
  end
end
