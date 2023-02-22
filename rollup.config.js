import resolve from "@rollup/plugin-node-resolve";
import { terser } from "rollup-plugin-terser";
import pkg from "./package.json";

export default [
  {
    input: pkg.module,
    output: {
      file: pkg.main,
      format: "esm",
      inlineDynamicImports: true
    },
    plugins: [
      resolve(),
      terser({
        mangle: false,
        compress: false,
        format: {
          beautify: true,
          indent_level: 2
        }
      })
    ]
  },
  {
    input: pkg.module,
    output: {
      file: "app/assets/builds/katalyst/govuk/formbuilder.min.js",
      format: "esm",
      inlineDynamicImports: true
    },
    plugins: [
      resolve(),
      terser({
        mangle: true,
        compress: true
      })
    ]
  }
]
