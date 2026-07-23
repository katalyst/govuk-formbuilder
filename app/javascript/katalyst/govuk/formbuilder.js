import {
  Button,
  CharacterCount,
  Checkboxes,
  ErrorSummary,
  FileUpload,
  PasswordInput,
  Radios,
} from "govuk-frontend/dist/govuk/all.mjs";
import { SupportError } from "govuk-frontend/dist/govuk/errors/index.mjs";
import {
  isInitialised,
  isSupported,
} from "govuk-frontend/dist/govuk/common/index.mjs";

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
    [FileUpload, config.fileUpload],
    [Radios],
    [PasswordInput, config.passwordInput],
  ];
  const $scope =
    (_config$scope = config.scope) != null ? _config$scope : document;
  components.forEach(([Component, config]) => {
    const selector = `[data-module="${Component.moduleName}"]`;
    // The scope itself can be a component root (an observed insertion is
    // often the component element, not a container around one).
    const $elements = [
      ...($scope instanceof Element && $scope.matches(selector)
        ? [$scope]
        : []),
      ...$scope.querySelectorAll(selector),
    ];
    $elements.forEach(($element) => {
      if (isInitialised($element, Component.moduleName)) return;

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

// The support markers are a JS-capability probe (govuk-frontend's own
// pattern): a browser that can run this bundle marks <body> so component
// initialisation and `govuk-frontend-supported`-gated CSS switch on. The
// server never renders the markers.
function markSupport(body) {
  body.classList.toggle("js-enabled", true);
  body.classList.toggle(
    "govuk-frontend-supported",
    "noModule" in HTMLScriptElement.prototype,
  );
}

function supportMarked(body) {
  const supported = "noModule" in HTMLScriptElement.prototype;

  return (
    body.classList.contains("js-enabled") &&
    body.classList.contains("govuk-frontend-supported") === supported
  );
}

function observe(body) {
  // A morph reconciles the live DOM against a server response that carries
  // no JS-set state, stripping the body markers, every component's
  // data-*-init flag, and all injected UI — with no lifecycle events. Losing
  // the markers is therefore the signal that a morph happened: re-mark, then
  // sweep. Construction is guarded per component (an already-initialised
  // root throws InitError, which initAll swallows), so the sweep only
  // (re)enhances roots whose flags were stripped. Re-marking is
  // check-then-set, so observing our own write terminates in one bounce.
  //
  // Registered before the childList observer: callbacks run in creation
  // order, so when a strip and insertions land in one batch the markers are
  // back before any arrival sweep consults isSupported().
  new MutationObserver(() => {
    if (supportMarked(body)) return;

    markSupport(body);
    initAll();
  }).observe(body, { attributes: true, attributeFilter: ["class"] });

  // Components can also arrive after load — lazily-loaded turbo frames,
  // stream inserts, any dynamic DOM — with no event in common. Enhance
  // added subtrees as they land; the per-component guard makes overlapping
  // sweeps harmless.
  new MutationObserver((mutations) => {
    for (const mutation of mutations) {
      for (const node of mutation.addedNodes) {
        if (node instanceof Element) initAll({ scope: node });
      }
    }
  }).observe(body, { childList: true, subtree: true });
}

// Entry point for the govuk_formbuilder_init snippet: mark the page, enhance
// it, and keep both maintained as the DOM changes. The observers attach to
// the <body> element itself, so a Turbo replace render — which swaps in a
// new body and re-executes the snippet — disposes and recreates them, while
// a morph retains the body and the observers with it.
function init() {
  const body = document.body;

  if (body.__govukFormbuilderInit) return;
  body.__govukFormbuilderInit = true;

  markSupport(body);
  initAll();
  observe(body);
}

// stimulus controllers
import controllers from "./controllers";

export {
  controllers as default,
  init,
  initAll,
  Button,
  CharacterCount,
  Checkboxes,
  ErrorSummary,
  PasswordInput,
  Radios,
};
