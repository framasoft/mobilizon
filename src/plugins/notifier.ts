import { escapeHtml } from "@/utils/html";
import { App } from "vue";

export class Notifier {
  private app: App;

  constructor(app: App) {
    this.app = app;
  }

  success(message: string): void {
    this.notification(message, "success");
  }

  error(message: string): void {
    this.notification(message, "danger");
  }

  info(message: string): void {
    this.notification(message, "info");
  }

  private notification(message: string, type: string) {
    this.app.config.globalProperties.$oruga.notification.open({
      message: escapeHtml(message),
      duration: 5000,
      position: "bottom-right",
      type,
      hasIcon: true,
    });
  }
}

export const notifierPlugin = {
  install(app: App) {
    const notifier = new Notifier(app);
    app.config.globalProperties.$notifier = notifier;
    app.provide("notifier", notifier);
  },
};
