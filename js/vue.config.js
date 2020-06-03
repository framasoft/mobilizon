const path = require("path");

module.exports = {
  runtimeCompiler: true,
  lintOnSave: true,
  outputDir: path.resolve(__dirname, "../priv/static"),
  chainWebpack: (config) => {
    const svgRule = config.module.rule("svg");

    svgRule.uses.clear();

    svgRule.use("vue-svg-loader").loader("vue-svg-loader");
  },
};
