# frozen_string_literal: true

# Exercises every field type the form builder supports:
#   name/email  -> govuk_text_field / govuk_email_field
#   bio         -> govuk_text_area
#   active      -> govuk_check_box_field
#   born_on     -> govuk_date_field
#   age         -> govuk_number_field
#   status      -> govuk_enum_select / _radio_buttons / _check_boxes
#   country     -> govuk_combobox (hotwire_combobox)
#   description -> govuk_rich_textarea (ActionText)
#   avatar      -> govuk_image_field (ActiveStorage)
#   cv          -> govuk_document_field (ActiveStorage)
class Profile < ApplicationRecord
  # Display-only virtual attributes used by the guide examples (never persisted).
  # These mirror the upstream guide's Person object so we can reproduce every
  # example variant without adding throwaway database columns.
  attr_accessor :password,
                :account_number,
                :price_per_kg,
                :national_insurance_number_with_spacing,
                :national_insurance_number_without_spacing,
                # fractional-width demo
                :full, :three_quarters, :two_thirds, :one_half, :one_third, :one_quarter,
                # absolute-width demo
                :twenty, :ten, :five, :four, :three, :two,
                # textarea page
                :responsibilities, :job_description, :curriculum_vitae,
                :education_history, :personal_statement,
                # select / radios pages (string-keyed collections)
                :old_department_id, :old_department_description, :laptop,
                # checkboxes page
                :other_language,
                # fieldset page
                :address_one, :address_two, :address_three, :postcode,
                # file-upload page
                :profile_photo

  # Typed (but column-less) so the date/time inputs round-trip through Rails
  # multiparameter assignment without needing throwaway database columns.
  attribute :date_of_birth, :date
  attribute :graduation_month, :date
  attribute :date_of_trade, :date
  attribute :time_of_birth, :time

  # Integer-typed so a selected option round-trips: these back collections whose
  # values are integer ids, and a string param wouldn't match on re-render.
  attribute :new_department_id, :integer
  attribute :lunch_id, :integer
  attribute :wednesday_lunch_id, :integer
  attribute :thursday_lunch_id, :integer
  attribute :terms_and_conditions_agreed, :integer

  # Multi-value checkbox collections. A checkbox is re-checked on round-trip only
  # when the submitted value matches the collection's option value by type, so we
  # register the attributes and normalise each element to that type (dropping the
  # blank hidden-field entry): integer ids for the id-keyed collections, symbols
  # for the value-keyed ones.
  attribute :department_ids
  attribute :lunch_ids
  attribute :wednesday_lunch_ids
  attribute :languages
  attribute :countries

  normalizes :department_ids, :lunch_ids, :wednesday_lunch_ids,
             with: ->(values) { Array(values).compact_blank.map(&:to_i) }
  normalizes :languages, :countries,
             with: ->(values) { Array(values).compact_blank.map(&:to_sym) }

  enum :status, { draft: 0, published: 1, archived: 2 }

  has_rich_text :description
  has_one_attached :avatar
  has_one_attached :cv
  has_many_attached :gallery

  COUNTRIES = ["Australia", "New Zealand", "United Kingdom", "Canada", "Ireland"].freeze

  validates :name, :email, :avatar, presence: true

  def to_s
    name.presence || "New profile"
  end
end
