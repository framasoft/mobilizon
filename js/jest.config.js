module.exports = {
  preset: "@vue/cli-plugin-unit-jest/presets/typescript-and-babel",
  collectCoverage: true,
  collectCoverageFrom: [
    "**/*.{vue,ts}",
    "!**/node_modules/**",
    "!get_union_json.ts",
  ],
  coverageReporters: ["html", "text", "text-summary"],
  reporters: ["default", "jest-junit"],
  // The following should fix the issue with svgs and ?inline loader (see Logo.vue), but doesn't work
  //
  // transform: {
  //   "^.+\\.svg$": "<rootDir>/tests/unit/svgTransform.js",
  // },
  // moduleNameMapper: {
  //   "^@/(.*svg)(\\?inline)$": "<rootDir>/src/$1",
  //   "^@/(.*)$": "<rootDir>/src/$1",
  // },
};
