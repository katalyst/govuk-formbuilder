import resolve from "@rollup/plugin-node-resolve"
import terser from "@rollup/plugin-terser"

export default [
  {
    input: "katalyst/govuk/formbuilder.js",
    output: {
        file: "app/assets/builds/katalyst/govuk/formbuilder.js",
        format: "esm",
        inlineDynamicImports: true
      },
    context: "window",
    plugins: [
      resolve({
        modulePaths: ["app/javascript"]
      }),
      terser({
        mangle: false,
        compress: false,
        format: {
          beautify: true,
          indent_level: 2
        }
      })
    ],
    external: ["@hotwired/stimulus", "@hotwired/turbo-rails", "trix"],
  },
  {
    input: "katalyst/govuk/formbuilder.js",
    output: {
      file: "app/assets/builds/katalyst/govuk/formbuilder.min.js",
      format: "esm",
      inlineDynamicImports: true,
      sourcemap: true
    },
    plugins: [
      resolve(),
      terser({
        mangle: true,
        compress: true
      })
    ],
    context: "window",
    plugins: [
      resolve({
        modulePaths: ["app/javascript"]
      }),
      terser({
        mangle: true,
        compress: true
      })
    ],
    external: ["@hotwired/stimulus", "@hotwired/turbo-rails", "trix"],
  }
]
