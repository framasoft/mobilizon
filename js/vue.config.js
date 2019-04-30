const Dotenv = require('dotenv-webpack');
const path = require('path');

module.exports = {
  lintOnSave: false,
  runtimeCompiler: true,
  outputDir: '../priv/static/js',
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
    output: {
      filename: 'app.js'
    }
  },
  chainWebpack: config => {
    config
        .plugin('html')
        .tap(args => {
          args[0].minify = {
            collapseWhitespace: true,
            removeComments: false,
            removeRedundantAttributes: true,
            removeScriptTypeAttributes: true,
            removeStyleLinkTypeAttributes: true,
            useShortDoctype: true
          };
          return args
        });

    config.module
        .rule("vue")
        .use("vue-svg-inline-loader")
        .loader("vue-svg-inline-loader")
        .options({ /* ... */ });
  }
};
