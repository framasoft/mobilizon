import vue from "@vitejs/plugin-vue";
import { defineConfig } from "vite";
import path from "path";
import { VitePWA } from "vite-plugin-pwa";
import { visualizer } from "rollup-plugin-visualizer";
// import { resolve, dirname } from "node:path";
// import { fileURLToPath } from "url";
// import vueI18n from "@intlify/vite-plugin-vue-i18n";

export default defineConfig(({ command }) => {
  const isDev = command !== "build";
  if (isDev) {
    // Terminate the watcher when Phoenix quits
    process.stdin.on("close", () => {
      process.exit(0);
    });

    process.stdin.resume();
  }

  return {
    plugins: [
      vue(),
      VitePWA({
        // registerType: "autoUpdate",
        strategies: "injectManifest",
        srcDir: "src",
        filename: "service-worker.ts",
        // injectRegister: "auto",
        // devOptions: {
        //   enabled: true,
        // },
      }),
      // vueI18n({
      //   /* options */
      //   // locale messages resource pre-compile option
      //   include: resolve(
      //     dirname(fileURLToPath(import.meta.url)),
      //     "./src/i18n/**"
      //   ),
      // }),
      visualizer(),
    ],
    build: {
      manifest: true,
      outDir: path.resolve(__dirname, "../priv/static"),
      emptyOutDir: true,
      sourcemap: isDev,
      rollupOptions: {
        // overwrite default .html entry
        input: {
          main: "src/main.ts",
        },
      },
    },
    resolve: {
      alias: {
        "@": path.resolve(__dirname, "./src"),
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
      setupFiles: path.resolve(__dirname, "./tests/unit/setup.ts"),
    },
  };
});
