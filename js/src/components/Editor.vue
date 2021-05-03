<template>
  <div v-if="editor">
    <div
      class="editor"
      :class="{ short_mode: isShortMode, comment_mode: isCommentMode }"
      id="tiptab-editor"
      :data-actor-id="currentActor && currentActor.id"
    >
      <div
        class="menubar bar-is-hidden"
        v-if="isDescriptionMode"
        :editor="editor"
      >
        <button
          class="menubar__button"
          :class="{ 'is-active': editor.isActive('bold') }"
          @click="editor.chain().focus().toggleBold().run()"
          type="button"
        >
          <b-icon icon="format-bold" />
        </button>

        <button
          class="menubar__button"
          :class="{ 'is-active': editor.isActive('italic') }"
          @click="editor.chain().focus().toggleItalic().run()"
          type="button"
        >
          <b-icon icon="format-italic" />
        </button>

        <button
          class="menubar__button"
          :class="{ 'is-active': editor.isActive('underline') }"
          @click="editor.chain().focus().toggleUnderline().run()"
          type="button"
        >
          <b-icon icon="format-underline" />
        </button>

        <button
          v-if="!isBasicMode"
          class="menubar__button"
          :class="{ 'is-active': editor.isActive('heading', { level: 1 }) }"
          @click="editor.chain().focus().toggleHeading({ level: 1 }).run()"
          type="button"
        >
          <b-icon icon="format-header-1" />
        </button>

        <button
          v-if="!isBasicMode"
          class="menubar__button"
          :class="{ 'is-active': editor.isActive('heading', { level: 2 }) }"
          @click="editor.chain().focus().toggleHeading({ level: 2 }).run()"
          type="button"
        >
          <b-icon icon="format-header-2" />
        </button>

        <button
          v-if="!isBasicMode"
          class="menubar__button"
          :class="{ 'is-active': editor.isActive('heading', { level: 3 }) }"
          @click="editor.chain().focus().toggleHeading({ level: 3 }).run()"
          type="button"
        >
          <b-icon icon="format-header-3" />
        </button>

        <button
          class="menubar__button"
          @click="showLinkMenu()"
          :class="{ 'is-active': editor.isActive('link') }"
          type="button"
        >
          <b-icon icon="link" />
        </button>

        <button
          v-if="editor.isActive('link')"
          class="menubar__button"
          @click="editor.chain().focus().unsetLink().run()"
          type="button"
        >
          <b-icon icon="link-off" />
        </button>

        <button
          class="menubar__button"
          v-if="!isBasicMode"
          @click="showImagePrompt()"
          type="button"
        >
          <b-icon icon="image" />
        </button>

        <button
          class="menubar__button"
          v-if="!isBasicMode"
          :class="{ 'is-active': editor.isActive('bulletList') }"
          @click="editor.chain().focus().toggleBulletList().run()"
          type="button"
        >
          <b-icon icon="format-list-bulleted" />
        </button>

        <button
          v-if="!isBasicMode"
          class="menubar__button"
          :class="{ 'is-active': editor.isActive('orderedList') }"
          @click="editor.chain().focus().toggleOrderedList().run()"
          type="button"
        >
          <b-icon icon="format-list-numbered" />
        </button>

        <button
          v-if="!isBasicMode"
          class="menubar__button"
          :class="{ 'is-active': editor.isActive('blockquote') }"
          @click="editor.chain().focus().toggleBlockquote().run()"
          type="button"
        >
          <b-icon icon="format-quote-close" />
        </button>

        <button
          v-if="!isBasicMode"
          class="menubar__button"
          @click="editor.chain().focus().undo().run()"
          type="button"
        >
          <b-icon icon="undo" />
        </button>

        <button
          v-if="!isBasicMode"
          class="menubar__button"
          @click="editor.chain().focus().redo().run()"
          type="button"
        >
          <b-icon icon="redo" />
        </button>
      </div>

      <bubble-menu
        v-if="editor && isCommentMode"
        class="bubble-menu"
        :editor="editor"
        :tippy-options="{ duration: 100 }"
      >
        <button
          class="menububble__button"
          :class="{ 'is-active': editor.isActive('bold') }"
          @click="editor.chain().focus().toggleBold().run()"
          type="button"
        >
          <b-icon icon="format-bold" />
          <span class="visually-hidden">{{ $t("Bold") }}</span>
        </button>

        <button
          class="menububble__button"
          :class="{ 'is-active': editor.isActive('italic') }"
          @click="editor.chain().focus().toggleItalic().run()"
          type="button"
        >
          <b-icon icon="format-italic" />
          <span class="visually-hidden">{{ $t("Italic") }}</span>
        </button>
      </bubble-menu>

      <editor-content class="editor__content" :editor="editor" />
    </div>
  </div>
</template>

<script lang="ts">
import { Component, Prop, Vue, Watch } from "vue-property-decorator";
import { Editor, EditorContent, BubbleMenu } from "@tiptap/vue-2";
import { defaultExtensions } from "@tiptap/starter-kit";
import Document from "@tiptap/extension-document";
import Paragraph from "@tiptap/extension-paragraph";
import Text from "@tiptap/extension-text";
import { IActor, IPerson, usernameWithDomain } from "../types/actor";
import CustomImage from "./Editor/Image";
import { UPLOAD_MEDIA } from "../graphql/upload";
import { listenFileUpload } from "../utils/upload";
import { CURRENT_ACTOR_CLIENT } from "../graphql/actor";
import Mention from "@tiptap/extension-mention";
import MentionOptions from "./Editor/Mention";
import OrderedList from "@tiptap/extension-ordered-list";
import ListItem from "@tiptap/extension-list-item";
import Underline from "@tiptap/extension-underline";
import Link from "@tiptap/extension-link";
import CharacterCount from "@tiptap/extension-character-count";

@Component({
  components: { EditorContent, BubbleMenu },
  apollo: {
    currentActor: {
      query: CURRENT_ACTOR_CLIENT,
    },
  },
})
export default class EditorComponent extends Vue {
  @Prop({ required: true }) value!: string;

  @Prop({ required: false, default: "description" }) mode!: string;

  @Prop({ required: false, default: 100_000_000 }) maxSize!: number;

  currentActor!: IPerson;

  editor: Editor | null = null;

  get isDescriptionMode(): boolean {
    return this.mode === "description" || this.isBasicMode;
  }

  get isCommentMode(): boolean {
    return this.mode === "comment";
  }

  get isShortMode(): boolean {
    return this.isBasicMode;
  }

  get isBasicMode(): boolean {
    return this.mode === "basic";
  }

  // eslint-disable-next-line
  insertMention(obj: { range: any; attrs: any }) {
    console.log("initialize Mention");
  }

  observer!: MutationObserver | null;

  mounted(): void {
    this.editor = new Editor({
      extensions: [
        Document,
        Paragraph,
        Text,
        OrderedList,
        ListItem,
        Mention.configure(MentionOptions),
        CustomImage,
        Underline,
        Link,
        CharacterCount.configure({
          limit: this.maxSize,
        }),
        ...defaultExtensions(),
      ],
      content: this.value,
      onUpdate: () => {
        this.$emit("input", this.editor?.getHTML());
      },
    });
  }

  @Watch("value")
  onValueChanged(val: string): void {
    if (!this.editor) return;
    if (val !== this.editor.getHTML()) {
      this.editor.commands.setContent(val, false);
    }
  }

  /**
   * Show a popup to get the link from the URL
   */
  showLinkMenu(): void {
    this.$buefy.dialog.prompt({
      message: this.$t("Enter the link URL") as string,
      inputAttrs: {
        type: "url",
      },
      trapFocus: true,
      onConfirm: (value) => {
        if (!this.editor) return undefined;
        this.editor.chain().focus().setLink({ href: value }).run();
      },
    });
  }

  /**
   * Show a file prompt, upload picture and insert it into editor
   */
  async showImagePrompt(): Promise<void> {
    const image = await listenFileUpload();
    try {
      const { data } = await this.$apollo.mutate({
        mutation: UPLOAD_MEDIA,
        variables: {
          file: image,
          name: image.name,
        },
      });
      if (data.uploadMedia && data.uploadMedia.url && this.editor) {
        this.editor
          .chain()
          .focus()
          .setImage({
            src: data.uploadMedia.url,
            // eslint-disable-next-line @typescript-eslint/ban-ts-comment
            // @ts-ignore
            "data-media-id": data.uploadMedia.id,
          })
          .run();
      }
    } catch (error) {
      console.error(error);
      if (error.graphQLErrors && error.graphQLErrors.length > 0) {
        this.$notifier.error(error.graphQLErrors[0].message);
      }
    }
  }

  /**
   * We use this to programatically insert an actor mention when creating a reply to comment
   */
  replyToComment(actor: IActor): void {
    if (!this.editor) return;
    this.editor
      .chain()
      .focus()
      .insertContent({
        type: "mention",
        attrs: {
          id: usernameWithDomain(actor),
        },
      })
      .insertContent(" ")
      .run();
  }

  focus(): void {
    this.editor?.chain().focus("end");
  }

  beforeDestroy(): void {
    this.editor?.destroy();
  }
}
</script>
<style lang="scss">
@import "./Editor/style.scss";

$color-black: #000;
$color-white: #eee;

.menubar {
  margin-bottom: 1rem;
  transition: visibility 0.2s 0.4s, opacity 0.2s 0.4s;

  &__button {
    font-weight: bold;
    display: inline-flex;
    background: transparent;
    border: 0;
    color: $color-black;
    padding: 0.2rem 0.5rem;
    margin-right: 0.2rem;
    border-radius: 3px;
    cursor: pointer;

    &:hover {
      background-color: rgba($color-black, 0.05);
    }

    &.is-active {
      background-color: rgba($color-black, 0.1);
    }
  }
}

.editor {
  position: relative;

  p.is-empty:first-child::before {
    content: attr(data-empty-text);
    float: left;
    color: #aaa;
    pointer-events: none;
    height: 0;
    font-style: italic;
  }

  .editor__content div.ProseMirror {
    min-height: 10rem;
  }

  &.short_mode {
    div.ProseMirror {
      min-height: 5rem;
    }
  }

  &.comment_mode {
    div.ProseMirror {
      min-height: 2rem;
    }
  }

  &__content {
    div.ProseMirror {
      min-height: 2.5rem;
      box-shadow: inset 0 1px 2px rgba(10, 10, 10, 0.1);
      background-color: white;
      border-radius: 4px;
      color: #363636;
      border: 1px solid #dbdbdb;
      padding: 12px 6px;

      &:focus {
        border-color: $background-color;
        outline: none;
      }
    }

    h1 {
      font-size: 2em;
    }

    h2 {
      font-size: 1.5em;
    }

    h3 {
      font-size: 1.25em;
    }

    ul,
    ol {
      padding-left: 1rem;
    }

    ul {
      list-style-type: disc;
    }

    li > p,
    li > ol,
    li > ul {
      margin: 0;
    }

    blockquote {
      border-left: 3px solid rgba($color-black, 0.1);
      color: rgba($color-black, 0.8);
      padding-left: 0.8rem;
      font-style: italic;

      p {
        margin: 0;
      }
    }

    img {
      max-width: 100%;
      border-radius: 3px;
    }
  }
}

.bubble-menu {
  display: flex;
  background-color: #0d0d0d;
  padding: 0.2rem;
  border-radius: 0.5rem;

  button {
    border: none;
    background: none;
    color: #fff;
    font-size: 0.85rem;
    font-weight: 500;
    padding: 0 0.2rem;
    opacity: 0.6;
    cursor: pointer;

    &:hover,
    &.is-active {
      opacity: 1;
    }
  }
}

.suggestion-list {
  padding: 0.2rem;
  border: 2px solid rgba($color-black, 0.1);
  font-size: 0.8rem;
  font-weight: bold;
  &__no-results {
    padding: 0.2rem 0.5rem;
  }
  &__item {
    border-radius: 5px;
    padding: 0.2rem 0.5rem;
    margin-bottom: 0.2rem;
    cursor: pointer;
    &:last-child {
      margin-bottom: 0;
    }
    &.is-selected,
    &:hover {
      background-color: rgba($color-white, 0.2);
    }
    &.is-empty {
      opacity: 0.5;
    }
  }

  .media + .media {
    margin-top: 0;
    padding-top: 0;
  }
}
.tippy-box[data-theme~="dark"] {
  background-color: $color-black;
  padding: 0;
  font-size: 1rem;
  text-align: inherit;
  color: $color-white;
  border-radius: 5px;
}

.visually-hidden {
  display: none;
}
</style>
