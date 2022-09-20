import { nodeListForEach } from "govuk-frontend/govuk-esm/common.mjs";
import Button from "govuk-frontend/govuk-esm/components/button/button.mjs";
import CharacterCount from "govuk-frontend/govuk-esm/components/character-count/character-count.mjs";
import Checkboxes from "govuk-frontend/govuk-esm/components/checkboxes/checkboxes.mjs";
import ErrorSummary from "govuk-frontend/govuk-esm/components/error-summary/error-summary.mjs";
import Radios from "govuk-frontend/govuk-esm/components/radios/radios.mjs";

function initAll (options) {
  // Set the options to an empty object by default if no options are passed.
  options = typeof options !== 'undefined' ? options : {}

  // Allow the user to initialise GOV.UK Frontend in only certain sections of the page
  // Defaults to the entire document if nothing is set.
  const scope = typeof options.scope !== 'undefined' ? options.scope : document

  const $buttons = scope.querySelectorAll('[data-module="govuk-button"]')
  nodeListForEach($buttons, function ($button) {
    new Button($button).init()
  })

  const $characterCounts = scope.querySelectorAll('[data-module="govuk-character-count"]')
  nodeListForEach($characterCounts, function ($characterCount) {
    new CharacterCount($characterCount).init()
  })

  const $checkboxes = scope.querySelectorAll('[data-module="govuk-checkboxes"]')
  nodeListForEach($checkboxes, function ($checkbox) {
    new Checkboxes($checkbox).init()
  })

  // Find first error summary module to enhance.
  const $errorSummary = scope.querySelector('[data-module="govuk-error-summary"]')
  new ErrorSummary($errorSummary).init()

  const $radios = scope.querySelectorAll('[data-module="govuk-radios"]')
  nodeListForEach($radios, function ($radio) {
    new Radios($radio).init()
  })
}

export {
  initAll,
  Button,
  CharacterCount,
  Checkboxes,
  ErrorSummary,
  Radios
}
