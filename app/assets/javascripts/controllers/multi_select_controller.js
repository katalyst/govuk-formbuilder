/**
 * A custom multi-select menu widget.
 */

import { Controller } from "@hotwired/stimulus";

export default class MultiSelectController extends Controller {
  static targets = ["summary"];
  static values = {
    open: Boolean,
  }

  connect() {
    this.modified = false;
  }

  /**
   * Toggle the menu.
   *
   * @return true of the menu is open after toggle.
   */
  toggleMenu(force = undefined) {
    const open = force !== undefined ? force : this.openValue;
    open ? this.closeMenu() : this.openMenu();
    return open;
  }

  /**
   * Open the menu by setting the aria-expanded attribute.
   */
  openMenu() {
    this.element.toggleAttribute("closing", false);
    this.openValue = true;
  }

  /**
   * Close the menu by unsetting the expanded attribute.
   *
   * The menu closes if it or its descendants lose focus, so we use a two
   * step set-then-check approach to allow the user to switch focus.
   */
  closeMenu() {
    // Blur occurs before focus, so when a blur occurs we want to prepare to close
    // the menu but wait until the new focus event has happened (using setTimeout)
    // so that if the new focus is inside this element it can cancel the close.
    this.element.toggleAttribute("closing", true);
    setTimeout(() => {
      if (this.element.hasAttribute("closing")) {
        this.element.toggleAttribute("closing", !open);
        this.openValue = false;
      }
    });
  }

  openValueChanged(open) {
    this.element.toggleAttribute("open", open);
    this.options.setAttribute("aria-expanded", open);

    if (!open && this.modified) {
      this.modified = false;
      this.element.dispatchEvent(new Event("change", { bubbles: true }));
    }
  }

  /**
   * Toggle whether an option is selected or not. A selected option should have
   * a corresponding hidden input that will submit its value to the form.
   *
   * @return true if the option was toggled
   */
  toggleOption(option) {
    if (option.getAttribute("disabled")) return false;

    this.modified = true;
    const selected = option.toggleAttribute("selected");

    if (selected) {
      const input = this.template.cloneNode();
      input.disabled = false;
      input.value = option.getAttribute("value");
      this.template.insertAdjacentElement("afterEnd", input);
    } else {
      this.element.querySelector(`input[value="${option.getAttribute("value")}"]`).remove();
    }

    this.updateResult();

    this.element.dispatchEvent(new Event("input", { bubbles: true }));
    return true;
  }

  /**
   * On change, update the 'result' field which summarises the selection for the
   * user. Should be consistent with the server's implementation.
   */
  updateResult() {
    const selected = this.element.querySelectorAll(`[role=option][selected]`);
    switch (selected.length) {
      case 0:
        this.summaryTarget.innerText = this.summaryTarget.getAttribute("placeholder");
        this.summaryTarget.classList.toggle("placeholder", true);
        break;
      case 1:
        this.summaryTarget.innerText = selected[0].innerText;
        this.summaryTarget.classList.toggle("placeholder", false);
        break;
      default:
        this.summaryTarget.innerText = selected[0].innerText + ` (+${selected.length - 1} more)`;
        this.summaryTarget.classList.toggle("placeholder", false);
        break;
    }
  }

  /**
   * Handle browser focus events on the input and its children.
   * If the input gains focus while closing then cancel the close.
   */
  focus(e) {
    if (this.element.hasAttribute("closing")) this.openMenu();
  }

  /**
   * Handle browser blur events on the input and its children.
   * The menu will close if the next focus event is not within this input.
   */
  blur(e) {
    this.closeMenu();
  }

  /**
   * Handles click events anywhere in the widget's dom, dispatches on target.
   *
   * Click on the result field opens the menu, while click on an option toggles the option.
   */
  click(e) {
    if (this.summaryTarget.contains(e.target)) {
      this.toggleMenu();
    } else {
      const option = e.target.closest("[role='option']");

      if (option) {
        e.preventDefault();
        this.toggleOption(option)
      }
    }
  }

  /**
   * Handles key down events anywhere within the widget's dom.
   */
  keydown(e) {
    let option;
    switch (e.key) {
      case "Enter":
        if (this.openValue) {
          this.summaryTarget.focus();
          this.closeMenu();
        } else {
          this.openMenu();
          this.element.querySelector("[role=option]").focus();
        }
        break;
      case "Escape":
        if (this.openValue) {
          this.closeMenu();
        }
        break;
      case "Down":
      case "ArrowDown":
        option = e.target.closest("[role=option]");
        if (option && option.nextElementSibling) {
          option.nextElementSibling.focus();
        } else if (!this.openValue) {
          this.openMenu();
          this.element.querySelector("[role=option]").focus();
        } else if (this.summaryTarget.contains(e.target)) {
          this.element.querySelector("[role=option]").focus();
        } else {
          return; // we have not handled this key press
        }
        break;
      case "Up":
      case "ArrowUp":
        option = e.target.closest("[role=option]");
        if (option && option.previousElementSibling) {
          option.previousElementSibling.focus();
        } else if (this.element.hasAttribute("open")) {
          this.closeMenu();
          this.summaryTarget.focus();
        } else {
          return; // we have not handled this key press
        }
        break;
      case " ":
        option = e.target.closest("[role=option]");
        if (option) {
          this.toggleOption(option);
        } else {
          this.openMenu();
        }
        break;
      default:
        return; // we have not handled this key press
    }

    e.preventDefault();
  }

  get options() {
    return this.element.querySelector("[role=listbox]");
  }

  get template() {
    return this.element.querySelector("input");
  }
}
