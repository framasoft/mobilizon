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
    module: {
      rules: [ // fixes https://github.com/graphql/graphql-js/issues/1272
        {
          test: /\.mjs$/,
          include: /node_modules/,
          type: 'javascript/auto',
        },
      ],
    },
  },
};
