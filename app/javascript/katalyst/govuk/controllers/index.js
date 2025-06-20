import DocumentFieldController from "./document_field_controller";
import ImageFieldController from "./image_field_controller";

const Definitions = [
  {
    identifier: "govuk-document-field",
    controllerConstructor: DocumentFieldController,
  },
  {
    identifier: "govuk-image-field",
    controllerConstructor: ImageFieldController,
  },
];

export { Definitions as default };
