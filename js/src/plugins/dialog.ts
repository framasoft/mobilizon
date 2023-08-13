import DialogComponent from "@/components/core/CustomDialog.vue";
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
    variant,
    hasIcon,
    size,
    onConfirm,
    onCancel,
    inputAttrs,
    hasInput,
  }: {
    title?: string;
    message: string;
    confirmText?: string;
    cancelText?: string;
    variant?: string;
    hasIcon?: boolean;
    size?: string;
    onConfirm?: (prompt: string) => void;
    onCancel?: (source: string) => void;
    inputAttrs?: Record<string, any>;
    hasInput?: boolean;
  }) {
    this.app.config.globalProperties.$oruga.modal.open({
      component: DialogComponent,
      props: {
        title,
        message,
        confirmText,
        cancelText,
        variant,
        hasIcon,
        size,
        onConfirm,
        onCancel,
        inputAttrs,
        hasInput,
      },
      autoFocus: false,
      contentClass: "!w-11/12",
    });
  }

  confirm({
    title,
    message,
    confirmText,
    cancelText,
    variant,
    hasIcon,
    size,
    onConfirm,
    onCancel,
  }: {
    title: string;
    message: string;
    confirmText?: string;
    cancelText?: string;
    variant: string;
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
        variant,
        hasIcon,
        size,
        onConfirm,
        onCancel,
      },
      contentClass: "!w-11/12",
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
