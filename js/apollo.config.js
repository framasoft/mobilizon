// apollo.config.js
module.exports = {
  client: {
    service: {
      name: "Mobilizon",
      // URL to the GraphQL API
      url: "http://localhost:4000/api",
    },
    // Files processed by the extension
    includes: ["src/**/*.vue", "src/**/*.js"],
  },
};
