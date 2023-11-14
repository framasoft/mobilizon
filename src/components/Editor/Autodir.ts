import { Extension } from "@tiptap/core";

/**
 * Allows to set dir="auto" on top nodes
 * Taken from https://github.com/ueberdosis/tiptap/issues/1621#issuecomment-918990408
 */
export const AutoDir = Extension.create({
  name: "AutoDir",
  addGlobalAttributes() {
    return [
      {
        types: [
          "heading",
          "paragraph",
          "bulletList",
          "orderedList",
          "blockquote",
        ],
        attributes: {
          autoDir: {
            renderHTML: () => ({
              dir: "auto",
            }),
            parseHTML: (element) => element.dir || "auto",
          },
        },
      },
    ];
  },
});
