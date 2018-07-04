const Dotenv = require('dotenv-webpack');

module.exports = {
  lintOnSave: false,
  runtimeCompiler: true,
  configureWebpack: {
    plugins: [
      new Dotenv(),
    ],
  },
};
