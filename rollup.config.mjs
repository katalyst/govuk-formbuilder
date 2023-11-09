import resolve from "@rollup/plugin-node-resolve"
import terser from "@rollup/plugin-terser"

export default [
  {
    input: "app/javascripts/katalyst/govuk/formbuilder.js",
    output: {
      file: "app/assets/builds/katalyst/govuk/formbuilder.js",
      format: "esm",
      inlineDynamicImports: true
    },
    context: "window",
    plugins: [
      resolve({
        modulePaths: ["app/javascript"]
      })
    ],
  },
  {
    input: "app/javascripts/katalyst/govuk/formbuilder.js",
    output: {
      file: "app/assets/builds/katalyst/govuk/formbuilder.min.js",
      format: "esm",
      inlineDynamicImports: true
    },
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
  }
]
