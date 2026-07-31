import { FileUpload } from "govuk-frontend/dist/govuk/all.mjs";
import {
  mergeConfigs,
  normaliseDataset,
} from "govuk-frontend/dist/govuk/common/configuration.mjs";

// CSS classes written or queried by this bundle follow the configured
// brand, mirroring the Ruby builder's class prefixes. Behavioural wiring
// (Stimulus identifiers, data-actions, events) is always govuk-prefixed.
// Set from the govuk_formbuilder_init snippet via initAll({ brand }).
const config = { brand: "govuk" };

export default config;

// The pseudo upload button, identified structurally — the button fronting
// the (hidden) file input it precedes — so the selector holds under any
// brand.
export const uploadButtonSelector = "[type='button']:has(+ input[type='file'])";

// The attachment field replaces govuk-frontend's FileUpload, so its
// vocabulary is FileUpload's strings plus the attachment additions — one
// table for the whole field. The inherited keys keep their upstream names:
// the data-i18n.* attribute shapes are the compatibility bar.
const Attachment = {
  moduleName: "govuk-attachment",
  defaults: {
    i18n: {
      ...FileUpload.defaults.i18n,
      uploadSucceeded: "Uploaded successfully",
      uploadFailed: "Upload failed — try again",
      retryButton: "Try again",
      fileRemoved: "%{filename} removed",
      removeButton: "Remove %{filename}",
      removeButtonContent: "Remove",
    },
  },
  schema: { properties: { i18n: { type: "object" } } },
};

// The wrapper's data-i18n.* attributes (the builder's text options) merged
// over the bundled defaults — what ConfigurableComponent would provide as
// this.config. Each controller constructs its own I18n from it, with locale
// resolved from its own root, matching govuk-frontend's component pattern.
export function attachmentConfig(wrapper) {
  return mergeConfigs(
    Attachment.defaults,
    normaliseDataset(Attachment, wrapper?.dataset ?? {}),
  );
}
