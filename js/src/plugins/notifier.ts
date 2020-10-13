/* eslint-disable no-shadow */
import VueInstance from "vue";
import { ColorModifiers } from "buefy/types/helpers.d";
import { Route, RawLocation } from "vue-router";

declare module "vue/types/vue" {
  interface Vue {
    $notifier: {
      success: (message: string) => void;
      error: (message: string) => void;
      info: (message: string) => void;
    };
    beforeRouteEnter?(
      to: Route,
      from: Route,
      next: (to?: RawLocation | false | ((vm: VueInstance) => void)) => void
    ): void;

    beforeRouteLeave?(
      to: Route,
      from: Route,
      next: (to?: RawLocation | false | ((vm: VueInstance) => void)) => void
    ): void;

    beforeRouteUpdate?(
      to: Route,
      from: Route,
      next: (to?: RawLocation | false | ((vm: VueInstance) => void)) => void
    ): void;
  }
}

export class Notifier {
  private readonly vue: typeof VueInstance;

  constructor(vue: typeof VueInstance) {
    this.vue = vue;
  }

  success(message: string): void {
    this.notification(message, "is-success");
  }

  error(message: string): void {
    this.notification(message, "is-danger");
  }

  info(message: string): void {
    this.notification(message, "is-info");
  }

  private notification(message: string, type: ColorModifiers) {
    this.vue.prototype.$buefy.notification.open({
      message,
      duration: 5000,
      position: "is-bottom-right",
      type,
      hasIcon: true,
    });
  }
}

/* eslint-disable */
export function NotifierPlugin(vue: typeof VueInstance): void {
  vue.prototype.$notifier = new Notifier(vue);
}
