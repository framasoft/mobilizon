const path = require("path");
const ForkTsCheckerWebpackPlugin = require("fork-ts-checker-webpack-plugin");

module.exports = {
  devServer: {
    proxy: "http://mobilizon1.com",
  },
  runtimeCompiler: true,
  lintOnSave: process.env.NODE_ENV !== "production",
  filenameHashing: true,
  productionSourceMap: false,
  outputDir: path.resolve(__dirname, "../priv/static"),
  configureWebpack: (config) => {
    // Limit the used memory when building
    // Source : https://stackoverflow.com/a/55810460/10204399
    // get a reference to the existing ForkTsCheckerWebpackPlugin
    const existingForkTsChecker = config.plugins.filter(
      (p) => p instanceof ForkTsCheckerWebpackPlugin
    )[0];

    // remove the existing ForkTsCheckerWebpackPlugin
    // so that we can replace it with our modified version
    config.plugins = config.plugins.filter(
      (p) => !(p instanceof ForkTsCheckerWebpackPlugin)
    );

    // copy the options from the original ForkTsCheckerWebpackPlugin
    // instance and add the memoryLimit property
    const forkTsCheckerOptions = existingForkTsChecker.options;
    forkTsCheckerOptions.memoryLimit = process.env.NODE_BUILD_MEMORY || 2048;

    config.plugins.push(new ForkTsCheckerWebpackPlugin(forkTsCheckerOptions));
  },
  chainWebpack: (config) => {
    // remove the prefetch plugin
    config.plugins.delete("prefetch");
  },
  css: {
    loaderOptions: {
      scss: {
        additionalData: `@import "@/variables.scss";`,
      },
    },
  },
};
