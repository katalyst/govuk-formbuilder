# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Profiles" do
  describe "GET /profiles/new" do
    before { get new_profile_path }

    it "responds successfully" do
      expect(response).to have_http_status(:ok)
    end

    it "renders text and email inputs" do
      expect(response.body).to include('name="profile[name]"').and include('name="profile[email]"')
    end

    it "renders a govuk date field" do
      expect(response.body).to include('name="profile[born_on(3i)]"')
    end

    it "renders an enum select with humanised options" do
      expect(response.body).to include('name="profile[status]"').and include("Published")
    end

    it "renders a hotwire combobox with its options" do
      expect(response.body).to include("hw-combobox").and include("Australia")
    end

    it "renders an action text rich text area" do
      expect(response.body).to include("trix-editor")
    end

    it "renders image and document file inputs" do
      expect(response.body).to include('name="profile[avatar]"').and include('name="profile[cv]"')
    end

    it "emits the formbuilder javascript initialiser" do
      expect(response.body).to include('import {initAll} from "@katalyst/govuk-formbuilder"')
    end
  end

  describe "POST /profiles" do
    let(:params) { { profile: { name: "Grace Hopper", email: "grace@example.com", status: "draft" } } }

    it "creates a profile" do
      expect { post profiles_path, params: params }.to change(Profile, :count).by(1)
    end

    it "redirects to the created profile" do
      post profiles_path, params: params
      expect(response).to redirect_to(Profile.last)
    end
  end
end
