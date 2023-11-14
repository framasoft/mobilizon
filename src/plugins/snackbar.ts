import SnackbarComponent from "@/components/core/CustomSnackbar.vue";
import { App } from "vue";

export class Snackbar {
  private app: App;

  constructor(app: App) {
    this.app = app;
  }

  open({
    message,
    variant,
    position,
    actionText,
    cancelText,
    onAction,
  }: {
    message?: string;
    queue?: boolean;
    indefinite?: boolean;
    variant?: string;
    position?: string;
    actionText?: string;
    cancelText?: string;
    onAction?: () => any;
  }) {
    this.app.config.globalProperties.$oruga.notification.open({
      component: SnackbarComponent,
      props: {
        message,
        // queue,
        // indefinite,
        actionText,
        cancelText,
        onAction,
        position: position ?? "bottom-right",
        variant: variant ?? "dark",
      },
      position: position ?? "bottom-right",
      variant: variant ?? "dark",
      duration: 5000000,
    });
  }
}

export const snackbarPlugin = {
  install(app: App) {
    const snackbar = new Snackbar(app);
    app.config.globalProperties.$snackbar = snackbar;
    app.provide("snackbar", snackbar);
  },
};
