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
  enum :status, { draft: 0, published: 1, archived: 2 }

  has_rich_text :description
  has_one_attached :avatar
  has_one_attached :cv

  COUNTRIES = ["Australia", "New Zealand", "United Kingdom", "Canada", "Ireland"].freeze

  validates :name, :email, presence: true

  def to_s
    name.presence || "New profile"
  end
end
