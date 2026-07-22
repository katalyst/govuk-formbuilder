import AttachmentController from "./attachment_controller";
import DocumentFieldController from "./document_field_controller";
import FileUploadController from "./file_upload_controller";
import ImageFieldController from "./image_field_controller";

const Definitions = [
  {
    identifier: "govuk-attachment",
    controllerConstructor: AttachmentController,
  },
  {
    identifier: "govuk-document-field",
    controllerConstructor: DocumentFieldController,
  },
  {
    identifier: "govuk-file-upload",
    controllerConstructor: FileUploadController,
  },
  {
    identifier: "govuk-image-field",
    controllerConstructor: ImageFieldController,
  },
];

export { Definitions as default };
