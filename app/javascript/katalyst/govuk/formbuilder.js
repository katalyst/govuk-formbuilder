import {
  Button,
  CharacterCount,
  Checkboxes,
  ErrorSummary,
  PasswordInput,
  Radios,
} from "govuk-frontend/dist/govuk/all.mjs";
import { SupportError } from "govuk-frontend/dist/govuk/errors/index.mjs";
import { isSupported } from "govuk-frontend/dist/govuk/common/index.mjs";

function initAll(config) {
  let _config$scope;
  config = typeof config !== "undefined" ? config : {};
  if (!isSupported()) {
    console.log(new SupportError());
    return;
  }
  const components = [
    [Button, config.button],
    [CharacterCount, config.characterCount],
    [Checkboxes],
    [ErrorSummary, config.errorSummary],
    [Radios],
    [PasswordInput, config.passwordInput],
  ];
  const $scope =
    (_config$scope = config.scope) != null ? _config$scope : document;
  components.forEach(([Component, config]) => {
    const $elements = $scope.querySelectorAll(
      `[data-module="${Component.moduleName}"]`,
    );
    $elements.forEach(($element) => {
      try {
        "defaults" in Component
          ? new Component($element, config)
          : new Component($element);
      } catch (error) {
        console.log(error);
      }
    });
  });
}

// stimulus controllers
import controllers from "./controllers";

export {
  controllers as default,
  initAll,
  Button,
  CharacterCount,
  Checkboxes,
  ErrorSummary,
  PasswordInput,
  Radios,
};
