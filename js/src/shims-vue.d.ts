declare module "*.vue" {
  import type { DefineComponent } from "vue";

  // eslint-disable-next-line @typescript-eslint/ban-types
  const component: DefineComponent<{}, {}, any>;
  export default component;
}

declare module "*.svg" {
  import Vue, { VueConstructor } from "vue";

  const content: VueConstructor<Vue>;
  export default content;
}
