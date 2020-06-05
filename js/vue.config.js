const path = require("path");

module.exports = {
  runtimeCompiler: true,
  lintOnSave: true,
  outputDir: path.resolve(__dirname, "../priv/static"),
};
