import vue from "@vitejs/plugin-vue";
import { defineConfig } from "vite";
import path from "path";
import { VitePWA } from "vite-plugin-pwa";
import { visualizer } from "rollup-plugin-visualizer";

export default defineConfig(({ command }) => {
  const isDev = command !== "build";
  if (isDev) {
    // Terminate the watcher when Phoenix quits
    process.stdin.on("close", () => {
      process.exit(0);
    });

    process.stdin.resume();
  }

  const isStory = Boolean(process.env.HISTOIRE);

  const plugins = [vue(), visualizer()];

  if (!isStory) {
    plugins.push(
      VitePWA({
        registerType: "autoUpdate",
        strategies: "injectManifest",
        srcDir: "src",
        filename: "service-worker.ts",
        // injectRegister: "auto",
        // devOptions: {
        //   enabled: true,
        // },
        manifest: {
          name: "Mobilizon",
          short_name: "Mobilizon",
          orientation: "portrait-primary",
          theme_color: "#ffd599",
          icons: [
            {
              src: "./img/icons/android-chrome-192x192.png",
              sizes: "192x192",
              type: "image/png",
            },
            {
              src: "./img/icons/android-chrome-512x512.png",
              sizes: "512x512",
              type: "image/png",
            },
            {
              src: "./img/icons/android-chrome-maskable-192x192.png",
              sizes: "192x192",
              type: "image/png",
              purpose: "maskable",
            },
            {
              src: "./img/icons/android-chrome-maskable-512x512.png",
              sizes: "512x512",
              type: "image/png",
              purpose: "maskable",
            },
          ],
        },
      })
    );
  }

  const build = {
    manifest: true,
    outDir: path.resolve(__dirname, "priv/static"),
    emptyOutDir: true,
    sourcemap: true,
  };

  if (!isStory) {
    // overwrite default .html entry
    build.rollupOptions = {
      input: {
        main: "src/main.ts",
      },
    };
  }

  return {
    plugins,
    build,
    resolve: {
      alias: {
        "@": path.resolve(__dirname, "./src"),
        unfetch: path.resolve(
          __dirname,
          "node_modules",
          "unfetch",
          "dist",
          "unfetch.mjs"
        ),
      },
    },
    css: {
      preprocessorOptions: {
        scss: {
          sassOptions: {
            quietDeps: true,
          },
        },
      },
    },
    test: {
      environment: "jsdom",
      resolve: {
        alias: {
          "@": path.resolve(__dirname, "./src"),
        },
      },
      coverage: {
        reporter: ["text", "json", "html"],
      },
      setupFiles: [path.resolve(__dirname, "./tests/unit/setup.ts")],
      include: [path.resolve(__dirname, "./tests/unit/specs/**/*.spec.ts")],
    },
  };
});
