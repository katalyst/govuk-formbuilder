import { Controller } from "@hotwired/stimulus";
import { I18n } from "govuk-frontend/dist/govuk/i18n.mjs";
import { FileUpload } from "govuk-frontend/dist/govuk/all.mjs";
import { createAttachment } from "./attachment_controller";

export default class FileUploadController extends Controller {
  connect() {
    if (!this.fileInput) {
      throw new Error(`Missing file input for ${this.element}`);
    }

    this.i18n = new I18n(FileUpload.defaults.i18n, { locale: "en" });
    this.id = this.uploadButton?.id ?? this.fileInput.id;

    // dragenter/dragleave are on the document so we can tell a move between
    // child elements from truly leaving the drop zone; the document outlives
    // any re-enhancement, so these bind once per controller lifecycle.
    document.addEventListener("dragenter", this.onDragenter);
    document.addEventListener("dragleave", this.onDragleave);

    this.enhance();

    // A morph reconciles this element against a server response that has no
    // JS-injected UI, in place and with no Stimulus lifecycle events (a
    // morph that changes the surrounding structure instead recreates the
    // element, which lands in connect()). The button vanishing without a
    // disconnect is the signal to re-enhance.
    this.morphObserver = new MutationObserver(this.onMorph);
    this.morphObserver.observe(this.element, { childList: true });
  }

  disconnect() {
    this.morphObserver?.disconnect();
    this.disabledObserver?.disconnect();
    this.uploadButton?.removeEventListener("click", this.onClick);
    this.uploadButton?.removeEventListener("dragover", this.onDragover);
    this.uploadButton?.removeEventListener("drop", this.onDrop);
    this.unbindInput();
    document.removeEventListener("dragenter", this.onDragenter);
    document.removeEventListener("dragleave", this.onDragleave);
    this.announcements?.remove();
  }

  // Builds the JS-only UI over the server-rendered markup: a pseudo button
  // fronting the (hidden) input, and the assertive announcements region.
  // Idempotent over fresh server markup or whatever a morph left behind.
  enhance() {
    const fileInput = this.fileInput;
    let uploadButton = this.uploadButton;

    if (!uploadButton) {
      // The label's `for` still points at the input's original id (now the
      // button's id), so the label labels the button. Give it an id too, so
      // the button's `aria-labelledby` reference resolves.
      this.ensureLabelId();
      fileInput.id = `${this.id}-input`;
      fileInput.toggleAttribute("hidden", true);
      uploadButton = createUploadButton(this.id, this.i18n, fileInput);
      fileInput.insertAdjacentElement("beforebegin", uploadButton);

      // The button is the drop target; its listeners die with a stripped
      // button and rebind with its replacement.
      uploadButton.addEventListener("click", this.onClick);
      uploadButton.addEventListener("dragover", this.onDragover);
      uploadButton.addEventListener("drop", this.onDrop);
    }

    // Appended to the drop zone (not between button and input, whose
    // adjacency the uploadButton getter relies on).
    if (!this.announcements) this.element.appendChild(createAnnouncements());

    // A morph may retain the input node (its listeners survive) or replace
    // it (they vanish); removing before adding makes rebinding safe in both.
    this.unbindInput();
    fileInput.addEventListener("change", this.onChange);
    fileInput.addEventListener("govuk:upload", this.onUpload);
    fileInput.addEventListener("govuk:remove", this.onRemove);

    // The injected button is not a real input, so it does not inherit the
    // file input's disabled state; mirror it, and keep mirroring it if the
    // input's `disabled` attribute changes at runtime.
    this.updateDisabledState();
    this.observeDisabledState();

    this.updateCount();
  }

  unbindInput() {
    this.fileInput?.removeEventListener("change", this.onChange);
    this.fileInput?.removeEventListener("govuk:upload", this.onUpload);
    this.fileInput?.removeEventListener("govuk:remove", this.onRemove);
  }

  onMorph = () => {
    if (this.uploadButton) return;

    // The morphed-in server response is the truth: files still held by the
    // input were either persisted (they came back as server figures) or
    // lost with the refresh, and a File handle on a retained figure node is
    // stale either way. Discard both, then rebuild the injected UI.
    this.fileInput.value = "";
    this.element.querySelectorAll("figure").forEach((figure) => {
      delete figure.file;
    });

    this.enhance();
  };

  // The label is rendered by the form group, outside the drop zone, and
  // carries only a `for` (no id). The injected button references `${id}-label`
  // in its `aria-labelledby`, so ensure the label has that id.
  ensureLabelId() {
    const label = document.querySelector(`label[for="${this.id}"]`);

    if (label && !label.id) label.id = `${this.id}-label`;
  }

  updateDisabledState() {
    if (!this.uploadButton) return;

    const disabled = this.fileInput.disabled;

    this.uploadButton.disabled = disabled;
    this.element.classList.toggle(
      "govuk-file-upload-wrapper--disabled",
      disabled,
    );
  }

  observeDisabledState() {
    this.disabledObserver?.disconnect();
    this.disabledObserver = new MutationObserver((mutations) => {
      for (const mutation of mutations) {
        if (mutation.attributeName === "disabled") this.updateDisabledState();
      }
    });

    this.disabledObserver.observe(this.fileInput, { attributes: true });
  }

  onClick = (event) => {
    this.fileInput.click();
  };

  // Drag & drop mirrors govuk-frontend's FileUpload: the button is the drop
  // target, the whole drop zone shows the dragging state, and enter/leave
  // are announced.
  // Prevent the default so the button is a valid drop target.
  onDragover = (event) => {
    event.preventDefault();
  };

  onDragenter = (event) => {
    this.updateDropzoneVisibility(event);
    // A dragenter immediately before a dragleave means the pointer moved to
    // another element rather than leaving the window.
    this.enteredAnotherElement = true;
  };

  onDragleave = () => {
    if (!this.enteredAnotherElement && !this.uploadButton.disabled) {
      this.hideDraggingState();
      this.announce(this.i18n.t("leftDropZone"));
    }

    this.enteredAnotherElement = false;
  };

  onDrop = (event) => {
    event.preventDefault();

    if (event.dataTransfer && this.canFillInput(event.dataTransfer)) {
      this.fileInput.files = event.dataTransfer.files;
      this.fileInput.dispatchEvent(new CustomEvent("change"));
      this.hideDraggingState();
    }
  };

  updateDropzoneVisibility(event) {
    if (this.uploadButton.disabled) return;
    if (!(event.target instanceof Node)) return;

    if (this.element.contains(event.target)) {
      if (event.dataTransfer && this.canDrop(event.dataTransfer)) {
        if (!this.isDragging) {
          this.showDraggingState();
          this.announce(this.i18n.t("enteredDropZone"));
        }
      }
    } else if (this.isDragging) {
      this.hideDraggingState();
      this.announce(this.i18n.t("leftDropZone"));
    }
  }

  showDraggingState() {
    this.uploadButton.classList.add("govuk-file-upload-button--dragging");
  }

  hideDraggingState() {
    this.uploadButton.classList.remove("govuk-file-upload-button--dragging");
  }

  announce(message) {
    if (this.announcements) this.announcements.textContent = message;
  }

  get announcements() {
    return this.element.querySelector(".govuk-file-upload-announcements");
  }

  // Whether a drop of this many files is allowed: any for a multiple input,
  // exactly one otherwise.
  matchesInputCapacity(numberOfFiles) {
    if (this.fileInput.multiple) return numberOfFiles > 0;

    return numberOfFiles === 1;
  }

  // During drag the files aren't readable, so count droppable items by kind.
  canDrop(dataTransfer) {
    if (dataTransfer.items.length) {
      return this.matchesInputCapacity(countFileItems(dataTransfer.items));
    }

    if (dataTransfer.types.length) {
      return dataTransfer.types.includes("Files");
    }

    return true;
  }

  canFillInput(dataTransfer) {
    return this.matchesInputCapacity(dataTransfer.files.length);
  }

  onChange = () => {
    const files = Array.from(this.fileInput.files);
    const figures = Array.from(this.element.querySelectorAll("figure"));

    // Re-selection replaces the FileList, so drop unclaimed previews whose
    // file is no longer in the input. Claimed figures own their file (an
    // upload is running or done) and are unaffected.
    figures.forEach((figure) => {
      if (figure.file && !files.includes(figure.file)) figure.remove();
    });

    // Render a figure per new file; each carries its File until a figure
    // controller claims it for upload (govuk:upload). Unclaimed files —
    // no endpoint, or no controller — stay in the input and submit as
    // ordinary multipart.
    files.forEach((file) => {
      if (figures.some((figure) => figure.file === file)) return;

      const attachment = createAttachment(this.fileInput, file);
      this.uploadButton.insertAdjacentElement("beforebegin", attachment);
    });

    this.updateCount();
  };

  // A figure claimed its file for upload: release it from the FileList so
  // the same bytes don't also submit as multipart.
  onUpload = ({ detail: { file } }) => {
    this.releaseFile(file);
    this.updateCount();
  };

  releaseFile(file) {
    const remaining = new DataTransfer();

    for (const held of this.fileInput.files) {
      if (held !== file) remaining.items.add(held);
    }

    this.fileInput.files = remaining.files;
  }

  onRemove = async (event) => {
    // govuk:remove is dispatched before the figure is removed so listeners
    // can cancel it; wait until the current task ends, when the removal
    // (or the cancellation) is a fact.
    await Promise.resolve();

    if (event.defaultPrevented) return;

    const { name, file } = event.detail;

    // A removed figure that never claimed an upload still owns a file in
    // the input; release it so it no longer submits.
    if (file) this.releaseFile(file);

    // The removal is an event, so it is announced through the assertive
    // announcements region; the polite status region only ever carries
    // state (the count), which updates in place.
    this.announce(`${name} removed`);
    this.updateCount();
  };

  updateCount() {
    const count = this.fileCount;

    if (count === 0) {
      this.statusTag.innerText = this.i18n.t("noFileChosen");
      this.uploadButton.classList.add("govuk-file-upload-button--empty");
    } else {
      this.statusTag.innerText = this.i18n.t("multipleFilesChosen", { count });
      this.uploadButton.classList.remove("govuk-file-upload-button--empty");
    }
  }

  get fileInput() {
    return this.element.querySelector("input[type='file']");
  }

  get uploadButton() {
    return this.element.querySelector(
      "[type='button']:has(+ input[type='file'])",
    );
  }

  get isDragging() {
    return this.uploadButton.classList.contains(
      "govuk-file-upload-button--dragging",
    );
  }

  get statusTag() {
    return this.element.querySelector("button [aria-live]");
  }

  get fileCount() {
    let count = this.fileInput.files.length;

    this.element
      .querySelectorAll(`select[name='${this.fileInput.name}']`)
      .forEach((select) => {
        // A figure still holding its unclaimed File is backed by a FileList
        // entry counted above.
        if (!select.closest("figure")?.file) count += 1;
      });

    if (!this.fileInput.multiple) count = Math.min(count, 1);

    return count;
  }
}

// Counts DataTransferItems whose kind is "file" (ignoring dragged text etc.).
function countFileItems(items) {
  return Array.from(items).filter((item) => item.kind === "file").length;
}

// A visually-hidden assertive live region for event announcements (drag
// enter/leave, removals), kept separate from the polite status region that
// carries the file count.
function createAnnouncements(brand = "govuk") {
  const region = document.createElement("span");
  region.className = `${brand}-file-upload-announcements ${brand}-visually-hidden`;
  region.setAttribute("aria-live", "assertive");
  return region;
}

function createUploadButton(id, i18n, fileInput, brand = "govuk") {
  const template = document.createElement("TEMPLATE");
  template.innerHTML = `
    <button
        class="${brand}-file-upload-button ${brand}-file-upload-button--empty"
        type="button"
        id="${id}"
        aria-labelledby="${id}-label ${id}-comma ${id}"
      >
      <span class="${brand}-body ${brand}-file-upload-button__status"
            aria-live="polite">${i18n.t("noFileChosen")}</span>
      <span class="${brand}-visually-hidden" id="${id}-comma">, </span>
      <span class="${brand}-file-upload-button__pseudo-button-container">
        <span class="${brand}-button
                     ${brand}-button--secondary
                     ${brand}-file-upload-button__pseudo-button">${i18n.t("chooseFilesButton")}</span>
        <span class="${brand}-body govuk-file-upload-button__instruction">${i18n.t("dropInstruction")}</span>
      </span>
    </button>
  `;
  const button = template.content.firstElementChild;

  // Carry the input's hint/error descriptions onto the button, so the control
  // the user actually operates is described the same way the input was.
  const describedBy = fileInput.getAttribute("aria-describedby");
  if (describedBy) button.setAttribute("aria-describedby", describedBy);

  return button;
}
