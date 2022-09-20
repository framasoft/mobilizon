/* eslint-env node */
require("@rushstack/eslint-patch/modern-module-resolution");

module.exports = {
  root: true,

  env: {
    node: true,
  },

  extends: [
    "eslint:recommended",
    "plugin:vue/vue3-essential",
    "@vue/eslint-config-typescript/recommended",
    "plugin:prettier/recommended",
    "@vue/eslint-config-prettier",
  ],

  plugins: ["prettier"],

  parserOptions: {
    ecmaVersion: 2020,
    parser: "@typescript-eslint/parser",
  },

  rules: {
    "no-debugger": process.env.NODE_ENV === "production" ? "warn" : "off",
    "no-underscore-dangle": [
      "error",
      {
        allow: ["__typename", "__schema"],
      },
    ],
    "@typescript-eslint/no-explicit-any": "off",
    "vue/max-len": [
      "off",
      {
        ignoreStrings: true,
        ignoreHTMLTextContents: true,
        ignoreTemplateLiterals: true,
        ignoreComments: true,
        template: 170,
        code: 80,
      },
    ],
    "prettier/prettier": "error",
    "@typescript-eslint/interface-name-prefix": "off",
    "@typescript-eslint/no-use-before-define": "off",
    "import/extensions": "off",
    "import/no-unresolved": "off",
    "no-shadow": "off",
    "@typescript-eslint/no-shadow": ["error"],
  },

  ignorePatterns: ["src/typings/*.d.ts", "vue.config.js"],
  globals: {
    GeolocationPositionError: true,
  },
};
