/// <reference types="@histoire/plugin-vue/components" />

import { defineConfig } from "histoire";
import { HstVue } from "@histoire/plugin-vue";
import path from "path";

export default defineConfig({
  plugins: [HstVue()],
  setupFile: path.resolve(__dirname, "./src/histoire.setup.ts"),
  viteNodeInlineDeps: [/date-fns/],
  // viteIgnorePlugins: ['vite-plugin-pwa', 'vite-plugin-pwa:build', 'vite-plugin-pwa:info'],
  tree: {
    groups: [
      {
        title: "Actors",
        include: (file) => /^src\/components\/Account/.test(file.path),
      },
      {
        title: "Address",
        include: (file) => /^src\/components\/Address/.test(file.path),
      },
      {
        title: "Comments",
        include: (file) => /^src\/components\/Comment/.test(file.path),
      },
      {
        title: "Discussion",
        include: (file) => /^src\/components\/Discussion/.test(file.path),
      },
      {
        title: "Events",
        include: (file) => /^src\/components\/Event/.test(file.path),
      },
      {
        title: "Groups",
        include: (file) => /^src\/components\/Group/.test(file.path),
      },
      {
        title: "Home",
        include: (file) => /^src\/components\/Home/.test(file.path),
      },
      {
        title: "Posts",
        include: (file) => /^src\/components\/Post/.test(file.path),
      },
      {
        title: "Others",
        include: () => true,
      },
    ],
  },
});
