# frozen_string_literal: true

# Serves a single guide example (one rendered form) into its own turbo frame.
# GET renders the form; POST round-trips it so validation/error states can be
# exercised in isolation from the other examples on the same page.
class ExamplesController < ApplicationController
  before_action :set_profile

  attr_reader :profile

  # Name of the submit button whose value ("succeed"/"error") drives the outcome.
  OUTCOME_PARAM = "outcome"
  GENERIC_ERROR = "Something is wrong"

  # Union of every attribute any example form can submit. This is a throwaway
  # demo object that is never persisted, so a broad list is fine.
  PERMITTED_ATTRIBUTES = [
    :name, :email, :website, :phone, :age, :password,
    :account_number, :price_per_kg,
    :national_insurance_number_with_spacing, :national_insurance_number_without_spacing,
    :full, :three_quarters, :two_thirds, :one_half, :one_third, :one_quarter,
    :twenty, :ten, :five, :four, :three, :two,
    :responsibilities, :job_description, :curriculum_vitae, :education_history, :personal_statement,
    :new_department_id, :lunch_id, :wednesday_lunch_id, :thursday_lunch_id,
    :old_department_id, :old_department_description, :laptop,
    :other_language, :terms_and_conditions_agreed,
    :address_one, :address_two, :address_three, :postcode, :profile_photo,
    "date_of_birth(1i)", "date_of_birth(2i)", "date_of_birth(3i)",
    "graduation_month(1i)", "graduation_month(2i)", "graduation_month(3i)",
    "date_of_trade(1i)", "date_of_trade(2i)", "date_of_trade(3i)",
    "time_of_birth(1i)", "time_of_birth(2i)", "time_of_birth(3i)",
    "time_of_birth(4i)", "time_of_birth(5i)", "time_of_birth(6i)",
    { department_ids: [], lunch_ids: [], wednesday_lunch_ids: [], languages: [], countries: [] }
  ].freeze

  def show
    # GET renders the form; POST always re-renders it with 422 (no persistence).
    # The button that was pressed decides whether we round-trip the value or
    # force a generic error onto the submitted field(s).
    if request.post?
      force_generic_errors if params[OUTCOME_PARAM] == "error"

      render(example_template, locals: { profile: }, status: :unprocessable_entity)
    else
      render(example_template, locals: { profile: })
    end
  end

  private

  def force_generic_errors
    submitted_attributes.each { |attr| profile.errors.add(attr, GENERIC_ERROR) }
  end

  # The attributes this particular form posted, so the error lands on exactly
  # the input(s) shown in the example. Multiparameter keys ("date_of_birth(2i)")
  # are collapsed to their base attribute so the error attaches correctly.
  def submitted_attributes
    return [] unless params.key?(:profile)

    profile_params.keys.map { |key| key.sub(/\(\d+i\)\z/, "") }.uniq.map(&:to_sym)
  end

  def example_template
    "examples/#{params[:page]}/#{params[:example]}"
  end

  def set_profile
    @profile = Profile.new(profile_params)
  end

  def profile_params
    return {} unless params.key?(:profile)

    params.require(:profile).permit(*PERMITTED_ATTRIBUTES)
  end
end
