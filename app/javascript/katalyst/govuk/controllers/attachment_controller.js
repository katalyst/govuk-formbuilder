import { Controller } from "@hotwired/stimulus";
import { DirectUploadController } from "@rails/activestorage";
import { I18n } from "govuk-frontend/dist/govuk/i18n.mjs";
import { closestAttributeValue } from "govuk-frontend/dist/govuk/common/closest-attribute-value.mjs";
import config, { attachmentConfig, uploadButtonSelector } from "../config";

class AttachmentUploadController extends DirectUploadController {
  async start(option) {
    this.dispatch("start");
    try {
      const attributes = await new Promise((resolve, reject) => {
        this.directUpload.create((error, attributes) =>
          error ? reject(error) : resolve(attributes),
        );
      });
      option.value = attributes.signed_id;
    } catch (error) {
      this.dispatch("error", { error });
      throw error;
    } finally {
      this.dispatch("end");
    }
  }
}

export default class AttachmentController extends Controller {
  connect() {
    this.config = attachmentConfig(
      this.element.closest(`.${config.brand}-file-upload-wrapper`),
    );
    this.i18n = new I18n(this.config.i18n, {
      locale: closestAttributeValue(this.element, "lang"),
    });

    this.select.addEventListener("change", this.change);
    this.previewPendingFile();
    this.uploadPendingFile();
  }

  disconnect() {
    this.select?.removeEventListener("change", this.change);
  }

  previewPendingFile() {
    const file = this.element.file;

    if (!file) return;

    if (!file.type.startsWith("image/")) {
      this.imageTag?.remove();
      return;
    }

    const preview = new FileReader();
    preview.onload = this.onPreviewReady;
    preview.readAsDataURL(file);
  }

  uploadPendingFile() {
    const file = this.element.file;

    if (!file) return;
    if (!this.input?.dataset.directUploadUrl) return;

    delete this.element.file;

    this.input.dispatchEvent(
      new CustomEvent("govuk:upload", { detail: { file } }),
    );

    this.performUpload(file);
  }

  async performUpload(file) {
    this.uploader = new AttachmentUploadController(this.input, file);

    // Update element state, clearing any earlier failure
    this.element.dataset.state = "uploading";
    this.statusText = "";
    this.retryButton?.remove();
    const progressTag = createProgressTag(this.filenameTag.id);
    this.captionTag.appendChild(progressTag);
    this.input.addEventListener("direct-upload:progress", this.progress);

    try {
      await this.uploader.start(this.inputOption);
      this.element.dataset.state = "upload-successful";
      this.statusText = this.i18n.t("uploadSucceeded");
    } catch (error) {
      console.warn(error);
      this.element.dataset.state = "upload-failed";
      this.statusText = this.i18n.t("uploadFailed");
      this.actionsTag?.prepend(createRetryButton(file.name, this.i18n));
    } finally {
      this.input.removeEventListener("direct-upload:progress", this.progress);
      progressTag.remove();
    }
  }

  /**
   * @param e {ProgressEvent<FileReader>} file reader event
   */
  onPreviewReady = (e) => {
    this.imageTag.src = e.target.result;
  };

  change = () => {
    if (this.select.value === "") this.destroy();
  };

  retry() {
    this.performUpload(this.directUpload.file);
    this.removeButton?.focus();
  }

  progress = ({ detail }) => {
    if (detail.id !== this.id) return;
    if (this.progressTag) this.progressTag.value = detail.progress;
  };

  destroy() {
    const focusTarget = this.uploadButton;

    const remove = new CustomEvent("govuk:remove", {
      detail: {
        name: this.element.querySelector(".filename")?.textContent,
        // Unclaimed figures still own a file in the input's FileList; pass
        // it so the file-upload controller can release it.
        file: this.element.file,
      },
      cancelable: true,
    });

    if (!this.input.dispatchEvent(remove)) return;

    this.element.remove();
    focusTarget?.focus();
  }

  get id() {
    return this.directUpload?.id ?? this.select.id;
  }

  get directUpload() {
    return this.uploader?.directUpload;
  }

  get input() {
    return this.element
      .closest(`.${config.brand}-file-upload-wrapper`)
      ?.querySelector("input[type=file]");
  }

  get uploadButton() {
    return this.element
      .closest(`.${config.brand}-file-upload-wrapper`)
      ?.querySelector(uploadButtonSelector);
  }

  set statusText(message) {
    const tag = this.element.querySelector("figcaption .status");

    if (tag) tag.textContent = message;
  }

  /**
   * @returns {HTMLElement} the figure's caption, or null
   */
  get captionTag() {
    return this.element.querySelector("figcaption");
  }

  /**
   * @returns {HTMLElement} the caption's filename span, or null
   */
  get filenameTag() {
    return this.element.querySelector("figcaption .filename");
  }

  /**
   * @returns {HTMLElement} the figure's actions container, or null
   */
  get actionsTag() {
    return this.element.querySelector(".actions");
  }

  get select() {
    return this.element.querySelector("select");
  }

  /**
   * @returns {HTMLOptionElement} the option that records the file's blob id
   */
  get inputOption() {
    return this.element.querySelector("option");
  }

  /**
   * @returns {HTMLImageElement} the preview image, or null
   */
  get imageTag() {
    return this.element.querySelector("img");
  }

  get progressTag() {
    return this.element.querySelector("progress");
  }

  get retryButton() {
    return this.element.querySelector(".actions button[data-action*='retry']");
  }

  get removeButton() {
    return this.element.querySelector(
      ".actions button[data-action*='destroy']",
    );
  }
}

let nextAttachmentId = 0;

export function createAttachment(input, file, i18n) {
  const template = document.createElement("TEMPLATE");
  const id = ++nextAttachmentId;

  template.innerHTML = `
    <figure class="${config.brand}-attachment" data-controller="govuk-attachment" aria-labelledby="attachment-${id}-filename">
      <img alt="" class="preview" src="">
      <figcaption class="caption" aria-atomic="true" aria-live="polite">
        <span id="attachment-${id}-filename" class="filename"></span>
        <span class="size"></span>
        <span class="status"></span>
      </figcaption>
      <div class="actions">
        <select id="attachment-${id}-input" name="${input.name}" aria-labelledby="attachment-${id}-filename">
          <option selected="selected" value=""></option>
          <option value=""></option>
        </select>
        <button type="button" class="${config.brand}-button ${config.brand}-button--secondary ${config.brand}-attachment__remove" data-action="govuk-attachment#destroy" data-module="govuk-button"></button>
      </div>
    </figure>
  `;

  const figure = template.content.firstElementChild;

  figure.querySelector(".filename").textContent = file.name;
  figure.querySelector(".size").textContent = humanSize(file.size);

  const [keep, remove] = figure.querySelectorAll("option");
  keep.textContent = file.name;
  remove.textContent = i18n.t("removeButton", { filename: file.name });

  const removeButton = figure.querySelector("button");
  removeButton.textContent = i18n.t("removeButtonContent");
  removeButton.setAttribute(
    "aria-label",
    i18n.t("removeButton", { filename: file.name }),
  );

  // The figure carries its File until an attachment controller connects and
  // claims it for upload; while it remains, the file is still in the input's
  // FileList and will submit as ordinary multipart.
  figure.file = file;

  return figure;
}

const UNITS = ["Bytes", "KB", "MB", "GB", "TB", "PB"];

function humanSize(bytes) {
  if (bytes === 1) return "1 Byte";
  if (bytes < 1024) return `${bytes} Bytes`;

  const exp = Math.min(Math.floor(Math.log2(bytes) / 10), UNITS.length - 1);
  const value = Number((bytes / 1024 ** exp).toPrecision(3));

  return `${value} ${UNITS[exp]}`;
}

function createRetryButton(filename, i18n) {
  const button = document.createElement("BUTTON");
  button.type = "button";
  button.className = `${config.brand}-button ${config.brand}-button--secondary ${config.brand}-attachment__retry`;
  button.textContent = i18n.t("retryButton");
  button.setAttribute("aria-label", `${i18n.t("retryButton")} ${filename}`);
  button.dataset.action = "govuk-attachment#retry";
  button.dataset.module = "govuk-button";
  return button;
}

function createProgressTag(labelId) {
  const progress = document.createElement("PROGRESS");
  progress.className = `${config.brand}-attachment-progress`;
  if (labelId) progress.setAttribute("aria-labelledby", labelId);
  progress.value = 0;
  progress.max = 100;
  return progress;
}
