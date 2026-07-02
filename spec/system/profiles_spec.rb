# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Profile form" do
  it "runs the GOV.UK Frontend javascript enhancements" do
    visit new_profile_path

    # govuk_formbuilder_init toggles this class on once the module script runs
    expect(page).to have_css("body.js-enabled", wait: 5)
  end

  it "enhances the country field into an interactive combobox", :aggregate_failures do
    visit new_profile_path

    expect(page).to have_css("[role=combobox]")

    combobox = find("[role=combobox]")

    # Opening the combobox reveals the (initially hidden) listbox options
    combobox.click
    expect(page).to have_css("[role=option]", text: "Australia", wait: 5)

    # Typing filters the options down
    combobox.send_keys("Aus")
    expect(page).to have_css("[role=option]", text: "Australia")
    expect(page).to have_no_css("[role=option]", text: "Canada")

    # Selecting an option writes back to the hidden field value
    find("[role=option]", text: "Australia").click
    expect(combobox.value).to eq("Australia")
    expect(page).to have_field("profile[country]", with: "Australia", type: :hidden)
  end
end
