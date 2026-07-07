# frozen_string_literal: true

require "rails_helper"

# Exercises the disclosure behaviours provided by GOV.UK Frontend's Checkboxes
# and Radios components: conditionally-revealed content (an option that shows an
# extra field when selected) and the checkbox "exclusive" option (a "none of the
# above" choice that clears the others). These run once `initAll` enhances the
# fieldset inside its lazily-loaded guide frame; the govuk inputs are visually
# hidden and driven via their labels, hence `allow_label_click`.
RSpec.describe "Checkbox and radio disclosure" do
  describe "checkboxes conditional reveal" do
    it "reveals and hides the conditional field as the option is toggled", :aggregate_failures do
      visit guide_page_path("checkboxes")

      within("#checkboxes__conditional_reveal") do
        # The revealed field is present in the DOM but hidden until "Other" is checked.
        expect(page).to have_field("profile[other_language]", visible: :hidden)

        check("Other", allow_label_click: true)
        expect(page).to have_field("profile[other_language]", visible: :visible)

        uncheck("Other", allow_label_click: true)
        expect(page).to have_field("profile[other_language]", visible: :hidden)
      end
    end
  end

  describe "checkboxes exclusive option" do
    it "clears other selections when the exclusive option is chosen, and vice versa", :aggregate_failures do
      visit guide_page_path("checkboxes")

      within("#checkboxes__exclusive_option") do
        check("France", allow_label_click: true)
        expect(page).to have_checked_field("profile-countries-france-field", visible: :all)

        # Selecting the exclusive "none of the above" option unchecks the others.
        check("profile-countries-none-field", allow_label_click: true)
        expect(page).to have_checked_field("profile-countries-none-field", visible: :all)
        expect(page).to have_unchecked_field("profile-countries-france-field", visible: :all)

        # Selecting any other option in turn clears the exclusive one.
        check("France", allow_label_click: true)
        expect(page).to have_unchecked_field("profile-countries-none-field", visible: :all)
      end
    end
  end

  describe "radios conditional content" do
    it "reveals content for the selected radio and hides it when another is chosen", :aggregate_failures do
      visit guide_page_path("radios")

      within("#radios__conditional_content") do
        expect(page).to have_field("profile[old_department_description]", visible: :hidden)

        choose("Other", allow_label_click: true)
        expect(page).to have_field("profile[old_department_description]", visible: :visible)

        # Radios are mutually exclusive, so picking another option hides the content.
        choose("Information Technology", allow_label_click: true)
        expect(page).to have_field("profile[old_department_description]", visible: :hidden)
      end
    end
  end
end
