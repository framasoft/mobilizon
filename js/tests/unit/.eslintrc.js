module.exports = {
  env: {
    mocha: true,
  },
  globals: {
    expect: true,
    sinon: true,
  },
  rules: {
    "import/no-extraneous-dependencies": [
      "error",
      { devDependencies: ["**/*.test.js", "**/*.spec.js"] },
    ],
  },
};
