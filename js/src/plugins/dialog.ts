import DialogComponent from "@/components/core/Dialog.vue";
import { App } from "vue";

export class Dialog {
  private app: App;

  constructor(app: App) {
    this.app = app;
  }

  prompt({
    title,
    message,
    confirmText,
    cancelText,
    type,
    hasIcon,
    size,
    onConfirm,
    onCancel,
    inputAttrs,
    variant,
  }: {
    title?: string;
    message: string;
    confirmText?: string;
    cancelText?: string;
    type?: string;
    hasIcon?: boolean;
    size?: string;
    onConfirm?: (prompt: string) => void;
    onCancel?: (source: string) => void;
    inputAttrs: Record<string, any>;
    variant?: string;
  }) {
    this.app.config.globalProperties.$oruga.modal.open({
      component: DialogComponent,
      props: {
        title,
        message,
        confirmText,
        cancelText,
        type,
        hasIcon,
        size,
        onConfirm,
        onCancel,
        inputAttrs,
        variant,
      },
    });
  }

  confirm({
    title,
    message,
    confirmText,
    cancelText,
    type,
    hasIcon,
    size,
    onConfirm,
    onCancel,
  }: {
    title: string;
    message: string;
    confirmText?: string;
    cancelText?: string;
    type: string;
    hasIcon?: boolean;
    size?: string;
    onConfirm: () => any;
    onCancel?: (source: string) => any;
  }) {
    console.debug("confirming something");
    this.app.config.globalProperties.$oruga.modal.open({
      component: DialogComponent,
      props: {
        title,
        message,
        confirmText,
        cancelText,
        type,
        hasIcon,
        size,
        onConfirm,
        onCancel,
      },
    });
  }
}

export const dialogPlugin = {
  install(app: App) {
    const dialog = new Dialog(app);
    app.config.globalProperties.$dialog = dialog;
    app.provide("dialog", dialog);
  },
};
