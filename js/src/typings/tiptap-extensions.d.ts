declare module 'tiptap-extensions' {
    import Vue from 'vue';

    export class Blockquote {}
    export class CodeBlock {}
    export class HardBreak {}
    export class Heading {
      constructor(object: object)
    }
    export class OrderedList {}
    export class BulletList {}
    export class ListItem {}
    export class TodoItem {}
    export class TodoList {}
    export class Bold {}
    export class Code {}
    export class Italic {}
    export class Link {}
    export class Strike {}
    export class Underline {}
    export class History {}
    export class Placeholder {
      constructor(object: object)
    }
    export class Mention {
      constructor(object: object)
    }
}
