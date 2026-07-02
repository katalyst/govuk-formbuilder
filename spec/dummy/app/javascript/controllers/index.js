import { application } from "controllers/application";

// Load the formbuilder stimulus controllers (image/document field previews).
import govuk from "@katalyst/govuk-formbuilder";

application.load(govuk);

import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading";
eagerLoadControllersFrom("controllers", application);
