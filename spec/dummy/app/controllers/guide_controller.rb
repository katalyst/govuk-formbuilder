# frozen_string_literal: true

# Renders the guide pages that mirror the doc pages the upstream form builder
# ships. Each page (see app/views/guide/*) lays out the example forms for one
# component; the forms themselves are served by ExamplesController.
class GuideController < ApplicationController
  def index; end

  # Guide pages are static templates in app/views/guide. We render the one
  # named in the URL, but only after confirming it is a known page so that
  # user input never reaches the render path.
  PAGES = Dir[Rails.root.join("app/views/guide/*.html.erb")]
            .map { |path| File.basename(path, ".html.erb") }
            .reject { |name| name == "index" }
            .freeze

  def show
    page = PAGES.find { |name| name == params[:page] }
    raise ActionController::RoutingError, "Unknown guide page" unless page

    render action: page
  end
end
