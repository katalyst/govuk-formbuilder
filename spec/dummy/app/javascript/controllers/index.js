import { application } from "controllers/application";

// The README's primary wiring under test: register the gem's controllers
// (the attachment field's whole enhancement plus the legacy image/document
// controllers) on the app's Stimulus application, with session-durable
// page enhancement.
import GOVUK from "@katalyst/govuk-formbuilder";

GOVUK.start(application);

import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading";
eagerLoadControllersFrom("controllers", application);
