declare module "tiptap-extensions" {
  import { Extension, Node, Mark } from "tiptap";

  export interface PlaceholderOptions {
    emptyNodeClass?: string;
    emptyNodeText?: string;
    showOnlyWhenEditable?: boolean;
    showOnlyCurrent?: boolean;
    emptyEditorClass: string;
  }
  export class Placeholder extends Extension {
    constructor(options?: PlaceholderOptions);
  }

  export interface TrailingNodeOptions {
    /**
     * Node to be at the end of the document
     *
     * defaults to 'paragraph'
     */
    node: string;
    /**
     * The trailing node will not be displayed after these specified nodes.
     */
    notAfter: string[];
  }
  export class TrailingNode extends Extension {
    constructor(options?: TrailingNodeOptions);
  }

  export interface HeadingOptions {
    levels?: number[];
  }

  export class History extends Extension {}
  export class Underline extends Mark {}
  export class Strike extends Mark {}
  export class Italic extends Mark {}
  export class Bold extends Mark {}
  export class BulletList extends Node {}
  export class ListItem extends Node {}
  export class OrderedList extends Node {}
  export class HardBreak extends Node {}
  export class Blockquote extends Node {}
  export class CodeBlock extends Node {}
  export class TodoItem extends Node {}
  export class Code extends Node {}
  export class HorizontalRule extends Node {}
  export class Link extends Node {}
  export class TodoList extends Node {}

  export class Heading extends Node {
    constructor(options?: HeadingOptions);
  }

  export class Table extends Node {}
  export class TableCell extends Node {}
  export class TableRow extends Node {}
  export class TableHeader extends Node {}

  export class Mention extends Node {}
}
