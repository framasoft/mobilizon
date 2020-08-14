const path = require("path");

module.exports = {
  runtimeCompiler: true,
  lintOnSave: true,
  filenameHashing: true,
  outputDir: path.resolve(__dirname, "../priv/static"),
  configureWebpack: {
    optimization: {
      splitChunks: {
        minSize: 10000,
        maxSize: 250000,
      },
    },
  },
};
