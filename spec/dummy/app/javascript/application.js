import "controllers";
import "@hotwired/turbo-rails";

import "trix";
import "@rails/actiontext";

// The page-load initAll() (see govuk_formbuilder_init) doesn't cover forms that
// arrive later inside lazily-loaded example turbo frames, so re-initialise the
// govuk-frontend components scoped to each frame as it loads.
import { initAll } from "@katalyst/govuk-formbuilder";

addEventListener("turbo:render", (event) => initAll({ scope: event.target }));
addEventListener("turbo:frame-load", (event) =>
  initAll({ scope: event.target }),
);
