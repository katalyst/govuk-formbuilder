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

// Component options captured from the initAll call, reused by every
// observer-driven sweep.
let options = {};

function enhance($scope = document) {
  if (!isSupported()) {
    console.log(new SupportError());
    return;
  }
  const components = [
    [Button, options.button],
    [CharacterCount, options.characterCount],
    [Checkboxes],
    [ErrorSummary, options.errorSummary],
    [FileUpload, options.fileUpload],
    [Radios],
    [PasswordInput, options.passwordInput],
  ];
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
  // The body markers are JS-set, so a morph — which reconciles the live DOM
  // against server HTML, with no lifecycle events — strips them, along with
  // every component's data-*-init flag. Missing markers signal the morph:
  // re-mark, then sweep; the isInitialised guard re-enhances only roots
  // whose flags were stripped. Re-marking is check-then-set, so observing
  // our own write terminates in one bounce.
  //
  // Registered before the arrival observer: callbacks run in creation
  // order, so markers are back before an arrival sweep consults
  // isSupported().
  new MutationObserver(() => {
    if (supportMarked(body)) return;

    markSupport(body);
    enhance();
  }).observe(body, { attributes: true, attributeFilter: ["class"] });

  // Components can also arrive after load — lazily-loaded turbo frames,
  // stream inserts, any dynamic DOM — with no event in common. Enhance
  // added subtrees as they land; the per-component guard makes overlapping
  // sweeps harmless.
  new MutationObserver((mutations) => {
    for (const mutation of mutations) {
      for (const node of mutation.addedNodes) {
        if (node instanceof Element) enhance(node);
      }
    }
  }).observe(body, { childList: true, subtree: true });
}

function setup(body) {
  if (!body || body.__govukFormbuilderInit) return;
  body.__govukFormbuilderInit = true;

  markSupport(body);
  enhance();
  observe(body);
}

// The gem's Stimulus controllers register exactly once, on whichever
// application claims them first: the consumer's (via start) or a gem-owned
// application created on demand (the snippet path, for apps not otherwise
// running Stimulus). Stimulus itself observes the whole document, so
// registration — unlike the body-scoped setup — survives Turbo visits.
let registered = false;

function register(application = undefined) {
  if (registered) return;
  registered = true;

  (application ?? Application.start()).load(controllers);
}

function applyConfig(config) {
  if (config.brand) brandConfig.brand = config.brand;
  options = config;
}

/**
 * Enhance the current <body>: mark it as JS-capable, enhance its GOV.UK
 * components, and observe it for arrivals and morphs. Scoped to the body it
 * ran against — it does not survive a body replacement, so render it with
 * every page (the govuk_formbuilder_init snippet at the end of <body>).
 * Registers the gem's Stimulus controllers on a gem-owned application
 * unless start() has already claimed them.
 *
 * @param {object} [config] per-component config (button, characterCount,
 *   errorSummary, fileUpload, passwordInput)
 * @param {string} [config.brand] CSS class prefix for injected UI (default "govuk")
 */
function initAll(config = {}) {
  applyConfig(config);
  register();
  setup(document.body);
}

let watching = false;

/**
 * Wire the gem into your Stimulus application and keep the page enhanced
 * for the life of the session, including across Turbo visits — call once
 * from your own bundle:
 *
 *   import GOVUK from "@katalyst/govuk-formbuilder";
 *   GOVUK.start(application);
 *
 * @param {object} [application] Stimulus application to register the gem's
 *   controllers on (a gem-owned application is created when omitted)
 * @param {object} [config] as initAll's config
 */
function start(application = undefined, config = {}) {
  applyConfig(config);
  register(application);

  if (!watching) {
    watching = true;

    // The body-scoped setup dies with each Turbo visit; the documentElement
    // survives them, so watch it and set up against every new body. Also
    // covers a start() before <body> exists — the body's insertion is
    // itself a childList mutation here.
    new MutationObserver(() => setup(document.body)).observe(
      document.documentElement,
      { childList: true },
    );
  }

  setup(document.body);
}

// stimulus controllers
import { Application } from "@hotwired/stimulus";
import controllers from "./controllers";
import brandConfig from "./config";

export default { start };

export {
  initAll,
  Button,
  CharacterCount,
  Checkboxes,
  ErrorSummary,
  PasswordInput,
  Radios,
};
