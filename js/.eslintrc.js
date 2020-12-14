module.exports = {
  root: true,

  env: {
    node: true,
  },

  extends: [
    "plugin:vue/essential",
    "eslint:recommended",
    "@vue/prettier",
    "@vue/typescript/recommended",
    "@vue/prettier/@typescript-eslint",
  ],

  plugins: ["prettier"],

  parserOptions: {
    ecmaVersion: 2020,
    parser: "@typescript-eslint/parser",
  },

  rules: {
    "no-console": process.env.NODE_ENV === "production" ? "warn" : "off",
    "no-debugger": process.env.NODE_ENV === "production" ? "warn" : "off",
    "no-underscore-dangle": [
      "error",
      {
        allow: ["__typename"],
      },
    ],
    "@typescript-eslint/no-explicit-any": "off",
    "cypress/no-unnecessary-waiting": "off",
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
};
