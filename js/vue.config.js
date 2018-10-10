const Dotenv = require('dotenv-webpack');

module.exports = {
  lintOnSave: false,
  runtimeCompiler: true,
  outputDir: '../priv/static',
  configureWebpack: {
    plugins: [
      new Dotenv(),
    ],
  },
};
