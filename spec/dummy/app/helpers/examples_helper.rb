# frozen_string_literal: true

module ExamplesHelper
  # Frame id shared between the guide page (which requests the frame) and the
  # example view (which answers it). Both must agree or turbo can't match them.
  def example_frame_id(page, example)
    "#{page}__#{example}"
  end

  # Renders a captioned, lazily-loaded turbo frame for one guide example. The
  # frame fetches its form from ExamplesController in its own request, keeping
  # each example isolated on the page.
  def guide_example(page, example, caption)
    tag.section(class: "flow") do
      concat(tag.h2(caption, class: "govuk-heading-m"))
      concat(turbo_frame_tag(example_frame_id(page, example),
                             src:     example_path(page, example),
                             loading: :lazy))
    end
  end

  # Every guide example shares these two buttons. "Succeed" round-trips the
  # submitted values; "Fail" forces a generic error onto whichever field(s) the
  # form submitted. Neither persists — see ExamplesController.
  def example_submit_buttons(form)
    form.govuk_submit("Succeed", name: ExamplesController::OUTCOME_PARAM, value: "succeed") do
      form.govuk_submit("Fail", secondary: true,
                        name: ExamplesController::OUTCOME_PARAM, value: "error")
    end
  end

  # ---------------------------------------------------------------------------
  # Collections that back the select / radios / checkboxes examples. These
  # mirror the sample data in the upstream guide's Setup::ExampleData so the
  # rendered forms match.
  # ---------------------------------------------------------------------------

  Department  = Struct.new(:id, :name, keyword_init: true)
  LunchOption = Struct.new(:id, :name, :description, keyword_init: true)

  def departments
    [
      Department.new(id: 1, name: "Sales"),
      Department.new(id: 2, name: "Marketing"),
      Department.new(id: 3, name: "Finance"),
    ]
  end

  def lunch_options
    [
      LunchOption.new(id: 1, name: "Salad", description: "Lettuce, tomato and cucumber"),
      LunchOption.new(id: 2, name: "Jacket potato", description: "With cheese and baked beans"),
    ]
  end

  def grouped_lunch_options
    {
      "Sandwiches" => { "Ploughman's lunch" => :pl, "Tuna mayo" => :tm },
      "Salads"     => { "Greek salad" => :gs, "Tabbouleh" => :tb },
    }
  end

  def laptops
    %w[thinkpad xps macbook_pro zenbook]
  end
end
