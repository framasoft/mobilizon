const Dotenv = require('dotenv-webpack');
const path = require('path');

module.exports = {
  lintOnSave: false,
  runtimeCompiler: true,
  outputDir: '../priv/static',
  configureWebpack: {
    plugins: [
      new Dotenv({ path: path.resolve(process.cwd(), '../.env') }),
    ],
  },
};
