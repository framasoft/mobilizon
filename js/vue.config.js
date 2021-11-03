const path = require("path");

module.exports = {
  outputDir: path.resolve(__dirname, "../priv/static"),
  chainWebpack: (config) => {
    // remove the prefetch plugin
    config.plugins.delete("prefetch");
  },
  pwa: {
    themeColor: "#ffd599", //not required for service worker, but place theme color here if manifest.json doesn't change the color
    workboxPluginMode: "InjectManifest",
    workboxOptions: {
      // swSrc is required in InjectManifest mode.
      swSrc: "./src/service-worker.ts",
      // ...other Workbox options...
    },
    manifestOptions: {
      orientation: "portrait-primary",
    },
  },
  css: {
    loaderOptions: {
      scss: {
        additionalData: `
        @use "@/variables.scss" as *;
        `,
        sassOptions: {
          quietDeps: true,
        },
      },
    },
  },
};
