// @ts-nocheck
import { Extension, Plugin } from "tiptap";

export default class MaxSize extends Extension {
  get name() {
    return "maxSize";
  }

  get defaultOptions() {
    return {
      maxSize: null,
    };
  }

  get plugins() {
    return [
      new Plugin({
        appendTransaction: (transactions, oldState, newState) => {
          const max = this.options.maxSize;
          const oldLength = oldState.doc.content.size;
          const newLength = newState.doc.content.size;

          if (newLength > max && newLength > oldLength) {
            let newTr = newState.tr;
            newTr.insertText("", max + 1, newLength);

            return newTr;
          }
        },
      }),
    ];
  }
}
