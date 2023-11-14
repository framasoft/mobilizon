import { Extension } from "@tiptap/vue-3";

export interface RichEditorKeyboardSubmitOptions {
  submit: () => void;
}

export default Extension.create<RichEditorKeyboardSubmitOptions>({
  name: "RichEditorKeyboardSubmit",
  addOptions() {
    return {
      submit: () => ({}),
    };
  },
  addKeyboardShortcuts() {
    return {
      "Ctrl-Enter": () => {
        this.options.submit();
        return true;
      },
    };
  },
});
