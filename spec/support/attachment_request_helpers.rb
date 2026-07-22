# frozen_string_literal: true

require "nokogiri"

# Helpers for request specs that exercise attachment params and the figures a
# failed submit re-renders.
module AttachmentRequestHelpers
  # A blob that exists but isn't attached — stands in for a file the browser
  # has already direct-uploaded and injected as a select option, not yet saved.
  def uploaded_blob(filename: "avatar.png", fixture: file_fixture("avatar.png"), content_type: "image/png")
    ActiveStorage::Blob.create_and_upload!(
      io:           File.open(fixture),
      filename:,
      content_type:,
    )
  end

  def figures
    Nokogiri::HTML(response.body).css("figure.govuk-attachment")
  end

  def figure_for(filename)
    figures.find { |figure| figure.css(".filename").text.include?(filename) }
  end

  # The signed id the figure would submit to keep the attachment: its select's
  # selected option value.
  def kept_signed_id(figure)
    figure.at_css("select option[selected]")&.attr("value")
  end
end
