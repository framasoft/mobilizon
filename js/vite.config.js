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
      visualizer(),
    ],
    build: {
      manifest: true,
      outDir: path.resolve(__dirname, "../priv/static"),
      emptyOutDir: true,
      sourcemap: true,
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
      setupFiles: path.resolve(__dirname, "./tests/unit/setup.ts"),
      include: [path.resolve(__dirname, "./tests/unit/specs/**/*.spec.ts")],
    },
  };
});
