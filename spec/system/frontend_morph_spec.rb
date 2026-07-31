# frozen_string_literal: true

require "rails_helper"

# The `govuk_formbuilder_init` snippet at the end of <body> runs the bundle's
# initAll, which marks the page as JS-capable (body classes js-enabled /
# govuk-frontend-supported), enhances it, and observes <body>. Turbo
# re-executes body scripts on a replace render, but a morph retains the live
# script node, so the snippet never re-runs: the incoming server body carries
# no class attribute, the morph strips the JS-set markers, and no lifecycle
# event fires. The bundle's marker-restore observer is the recovery — missing
# markers signal the morph; re-mark, then re-sweep. These examples pin that
# recovery: support markers and component initialisation must survive morphs.
#
# A failed profile update is the morph driver: the layout opts into
# `turbo-refresh-method: morph`, so the 422 re-render morphs in place. The
# first failure also inserts the error summary (a structure change); a
# second failure patches the existing summary in place — the two shapes a
# morph can take.
RSpec.describe "GOV.UK Frontend javascript re-initialising after a morph", :aggregate_failures do
  let(:profile) { create(:profile) }

  it "keeps the JS-support marker on <body> across morphs" do
    visit edit_profile_path(profile)

    expect(page).to have_css("body.govuk-frontend-supported")

    fill_in "Name", with: ""
    click_button "Continue"

    # The summary's arrival signals the first morph has completed.
    expect(page).to have_css(".govuk-error-summary")
    expect(page).to have_css("body.govuk-frontend-supported")

    fill_in "Email", with: ""
    click_button "Continue"

    # A second, structure-stable morph; the added error entry signals it.
    expect(page).to have_css(".govuk-error-summary li", count: 2)
    expect(page).to have_css("body.govuk-frontend-supported")
  end

  it "re-enhances quietly, skipping already-initialised components" do
    visit edit_profile_path(profile)

    # Re-enhancement sweeps overlap by design — the marker-restore sweep and
    # the arriving-node sweep can visit the same root in one morph — so an
    # already-enhanced root must be skipped, not constructed-and-caught:
    # the sweep logs every catch, which would spam the console with
    # InitErrors on every morph.
    page.execute_script(<<~JS)
      window.__initErrors = [];
      const log = console.log.bind(console);
      console.log = (...args) => {
        if (/InitError|SupportError/.test(String(args[0]))) {
          window.__initErrors.push(String(args[0]));
        }
        log(...args);
      };
    JS

    fill_in "Name", with: ""
    click_button "Continue"

    expect(page).to have_css(".govuk-error-summary")
    expect(page.evaluate_script("window.__initErrors")).to eq([])
  end

  it "initialises a component that arrives with the morph" do
    visit edit_profile_path(profile)

    fill_in "Name", with: ""
    click_button "Continue"

    # The error summary first exists in the morphed response. govuk-frontend
    # moves focus to it when it initialises, so focus is the observable
    # outcome — initialisation failures are swallowed, only behaviour can
    # fail loudly.
    expect(page).to have_css(".govuk-error-summary:focus")
  end
end
