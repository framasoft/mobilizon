declare module 'tiptap' {
    import Vue from 'vue';
    export class Editor {
      public constructor({});
      public commands: {
        mention: Function,
      };

      public setOptions({}): void;
      public setContent(content: string): void;
      public focus(): void;
      public getHTML(): string;
      public destroy(): void;
    }

    export class Node {}

    export class Plugin {
      public constructor({});
    }

    export class EditorMenuBar extends Vue {}

    export class EditorContent extends Vue {}

    export class EditorMenuBubble extends Vue {}
}
