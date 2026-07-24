# frozen_string_literal: true

# Steers where a form's direct uploads go, for system specs that need to
# observe transient upload states or exercise failure paths against real
# (unstubbed) XHRs. Call a helper before visiting the page — the endpoint is
# rendered into the field's markup, not injected with JavaScript.
#
# Including this module restores the default form builder after each example.
module DirectUploadHelpers
  def self.included(base)
    base.after do
      BlockingDirectUploadsController.release_held
      ApplicationController.default_form_builder(GOVUKDesignSystemFormBuilder::FormBuilder)
    end
  end

  # Points direct uploads at a route that holds each request until released,
  # so transient upload states are observable — the default endpoint can
  # settle a small file before Capybara's first poll.
  def block_direct_uploads
    BlockingDirectUploadsController::QUEUE.clear
    use_direct_upload_url("/blocking_direct_uploads")
  end

  # Releases one held direct upload: with :ok it proceeds normally, with an
  # HTTP status the endpoint responds with that status instead.
  def release_direct_uploads(result = :ok)
    BlockingDirectUploadsController.release(result)
  end

  # Points direct uploads at a missing route so the create XHR fails.
  def break_direct_uploads
    use_direct_upload_url("/missing-direct-uploads")
  end

  # Renders fields without data-direct-upload-url, so the enhanced UI runs
  # in no-upload mode: previews without uploads, multipart submission.
  def disable_direct_uploads
    use_direct_upload_url(nil)
  end

  # Swaps in a form builder that overrides direct_upload_url — the same
  # extension point engine builders use.
  def use_direct_upload_url(url)
    builder = Class.new(GOVUKDesignSystemFormBuilder::FormBuilder) do
      define_method(:direct_upload_url) { url }
    end

    ApplicationController.default_form_builder(builder)
  end
end
