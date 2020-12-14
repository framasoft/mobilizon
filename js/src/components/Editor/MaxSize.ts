// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-nocheck
import { Extension, Plugin } from "tiptap";

export default class MaxSize extends Extension {
  // eslint-disable-next-line class-methods-use-this
  // eslint-disable-next-line @typescript-eslint/explicit-module-boundary-types
  get name() {
    return "maxSize";
  }

  // eslint-disable-next-line class-methods-use-this
  // eslint-disable-next-line @typescript-eslint/explicit-module-boundary-types
  get defaultOptions() {
    return {
      maxSize: null,
    };
  }

  // eslint-disable-next-line @typescript-eslint/explicit-module-boundary-types
  get plugins() {
    return [
      new Plugin({
        appendTransaction: (transactions, oldState, newState) => {
          const max = this.options.maxSize;
          const oldLength = oldState.doc.content.size;
          const newLength = newState.doc.content.size;

          if (newLength > max && newLength > oldLength) {
            const newTr = newState.tr;
            newTr.insertText("", max + 1, newLength);

            return newTr;
          }
        },
      }),
    ];
  }
}
