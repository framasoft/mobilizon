<template>
  <div v-if="editor">
    <div
      class="editor"
      :class="{ short_mode: isShortMode, comment_mode: isCommentMode }"
      id="tiptab-editor"
      :data-actor-id="currentActor && currentActor.id"
    >
      <div v-if="isDescriptionMode" :editor="editor">
        <div class="menubar bar-is-hidden">
          <button
            class="menubar__button"
            :class="{ 'is-active': editor.isActive('bold') }"
            @click="editor.chain().focus().toggleBold().focus().run()"
            type="button"
          >
            <b-icon icon="format-bold" />
          </button>

          <button
            class="menubar__button"
            :class="{ 'is-active': editor.isActive('italic') }"
            @click="editor.chain().focus().toggleItalic().focus().run()"
            type="button"
          >
            <b-icon icon="format-italic" />
          </button>

          <button
            class="menubar__button"
            :class="{ 'is-active': editor.isActive('underline') }"
            @click="editor.chain().focus().toggleUnderline().focus().run()"
            type="button"
          >
            <b-icon icon="format-underline" />
          </button>

          <button
            v-if="!isBasicMode"
            class="menubar__button"
            :class="{ 'is-active': editor.isActive('heading', { level: 1 }) }"
            @click="
              editor.chain().focus().toggleHeading({ level: 1 }).focus().run()
            "
            type="button"
          >
            <b-icon icon="format-header-1" />
          </button>

          <button
            v-if="!isBasicMode"
            class="menubar__button"
            :class="{ 'is-active': editor.isActive('heading', { level: 2 }) }"
            @click="
              editor.chain().focus().toggleHeading({ level: 2 }).focus().run()
            "
            type="button"
          >
            <b-icon icon="format-header-2" />
          </button>

          <button
            v-if="!isBasicMode"
            class="menubar__button"
            :class="{ 'is-active': editor.isActive('heading', { level: 3 }) }"
            @click="
              editor.chain().focus().toggleHeading({ level: 3 }).focus().run()
            "
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
            @click="editor.chain().focus().toggleBulletList().focus().run()"
            type="button"
          >
            <b-icon icon="format-list-bulleted" />
          </button>

          <button
            v-if="!isBasicMode"
            class="menubar__button"
            :class="{ 'is-active': editor.isActive('orderedList') }"
            @click="editor.chain().focus().toggleOrderedList().focus().run()"
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
      </div>

      <bubble-menu
        v-if="editor && isCommentMode"
        :editor="editor"
        :keep-in-bounds="true"
        v-slot="{ menu }"
      >
        <div
          class="menububble"
          :class="{ 'is-active': menu.isActive }"
          :style="`left: ${menu.left}px; bottom: ${menu.bottom}px;`"
        >
          <button
            class="menububble__button"
            :class="{ 'is-active': editor.isActive('bold') }"
            @click="editor.chain().focus().toggleBold().focus().run()"
            type="button"
          >
            <b-icon icon="format-bold" />
            <span class="visually-hidden">{{ $t("Bold") }}</span>
          </button>

          <button
            class="menububble__button"
            :class="{ 'is-active': editor.isActive('italic') }"
            @click="editor.chain().focus().toggleItalic().focus().run()"
            type="button"
          >
            <b-icon icon="format-italic" />
            <span class="visually-hidden">{{ $t("Italic") }}</span>
          </button>
        </div>
      </bubble-menu>

      <editor-content class="editor__content" :editor="editor" />
    </div>
    <div class="suggestion-list" v-show="showSuggestions" ref="suggestions">
      <template v-if="hasResults">
        <div
          v-for="(actor, index) in filteredActors"
          :key="actor.id"
          class="media suggestion-list__item"
          :class="{ 'is-selected': navigatedActorIndex === index }"
          @click="selectActor(actor)"
        >
          <div class="media-left">
            <figure class="image is-16x16" v-if="actor.avatar">
              <img :src="actor.avatar.url" alt="" />
            </figure>
          </div>
          <div class="media-content">
            {{ actor.name }}
          </div>
        </div>
      </template>
      <div v-else class="suggestion-list__item is-empty">
        {{ $t("No profiles found") }}
      </div>
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
import tippy, { Instance, sticky } from "tippy.js";
// import { SEARCH_PERSONS } from "../graphql/search";
import { Actor, IActor, IPerson } from "../types/actor";
import CustomImage from "./Editor/Image";
import { UPLOAD_MEDIA } from "../graphql/upload";
import { listenFileUpload } from "../utils/upload";
import { CURRENT_ACTOR_CLIENT } from "../graphql/actor";
import { IComment } from "../types/comment.model";
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

  /**
   * Editor Suggestions
   */
  query!: string | null;

  filteredActors: IActor[] = [];

  suggestionRange!: Record<string, unknown> | null;

  navigatedActorIndex = 0;

  popup!: Instance[] | null;

  get isDescriptionMode(): boolean {
    return this.mode === "description" || this.isBasicMode;
  }

  get isCommentMode(): boolean {
    return this.mode === "comment";
  }

  get isShortMode(): boolean {
    return this.isBasicMode;
  }

  get hasResults(): boolean {
    return this.filteredActors.length > 0;
  }

  get showSuggestions(): boolean {
    return (this.query || this.hasResults) as boolean;
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
      onUpdate: ({ editor }) => {
        this.$emit("input", editor.getHTML());
      },
    });
    this.editor.commands.setContent(this.value);
  }

  @Watch("value")
  onValueChanged(val: string): void {
    if (!this.editor) return;
    if (val !== this.editor.getHTML()) {
      this.editor.commands.setContent(val, false);
    }
  }

  // eslint-disable-next-line @typescript-eslint/ban-types
  showLinkMenu(): Function | undefined {
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
    return undefined;
  }

  upHandler(): void {
    this.navigatedActorIndex =
      (this.navigatedActorIndex + this.filteredActors.length - 1) %
      this.filteredActors.length;
  }

  /**
   * navigate to the next item
   * if it's the last item, navigate to the first one
   */
  downHandler(): void {
    this.navigatedActorIndex =
      (this.navigatedActorIndex + 1) % this.filteredActors.length;
  }

  enterHandler(): void {
    const actor = this.filteredActors[this.navigatedActorIndex];
    if (actor) {
      this.selectActor(actor);
    }
  }

  /**
   * we have to replace our suggestion text with a mention
   * so it's important to pass also the position of your suggestion text
   * @param actor IActor
   */
  selectActor(actor: IActor): void {
    const actorModel = new Actor(actor);
    this.insertMention({
      range: this.suggestionRange,
      attrs: {
        id: actorModel.id,
        // usernameWithDomain returns with a @ prefix and tiptap adds one itself
        label: actorModel.usernameWithDomain().substring(1),
      },
    });
    if (!this.editor) return;
    this.editor.commands.focus();
  }

  /** We use this to programatically insert an actor mention when creating a reply to comment */
  replyToComment(comment: IComment): void {
    if (!comment.actor) return;
    // const actorModel = new Actor(comment.actor);
    if (!this.editor) return;
    // this.editor.commands.mention({
    //   id: actorModel.id,
    //   label: actorModel.usernameWithDomain().substring(1),
    // });
    this.editor.commands.focus();
  }

  /**
   * renders a popup with suggestions
   * tiptap provides a virtualNode object for using popper.js (or tippy.js) for popups
   * @param node
   */
  renderPopup(node: Element): void {
    if (this.popup) {
      return;
    }
    this.popup = tippy("#mobilizon", {
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      getReferenceClientRect: node.getBoundingClientRect,
      appendTo: () => document.body,
      content: this.$refs.suggestions as HTMLElement,
      trigger: "mouseenter",
      interactive: true,
      sticky: true, // make sure position of tippy is updated when content changes
      plugins: [sticky],
      showOnCreate: true,
      theme: "dark",
      placement: "top-start",
      inertia: true,
      duration: [400, 200],
    }) as Instance[];
  }

  destroyPopup(): void {
    if (this.popup) {
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      this.popup[0].destroy();
      this.popup = null;
    }
    if (this.observer) {
      this.observer.disconnect();
    }
  }

  /**
   * Show a file prompt, upload picture and insert it into editor
   * @param command
   */
  // eslint-disable-next-line @typescript-eslint/ban-types
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

  beforeDestroy(): void {
    if (!this.editor) return;
    this.destroyPopup();
    this.editor.destroy();
  }
}
</script>
<style lang="scss">
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

    word-wrap: break-word;

    h1 {
      font-size: 2em;
    }

    h2 {
      font-size: 1.5em;
    }

    h3 {
      font-size: 1.25em;
    }

    * {
      caret-color: currentColor;
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

.menububble {
  position: absolute;
  display: flex;
  z-index: 20;
  background: $color-black;
  border-radius: 5px;
  padding: 0.3rem;
  margin-bottom: 0.5rem;
  transform: translateX(-50%);
  visibility: hidden;
  opacity: 0;
  transition: opacity 0.2s, visibility 0.2s;

  &.is-active {
    opacity: 1;
    visibility: visible;
  }

  &__button {
    display: inline-flex;
    background: transparent;
    border: 0;
    color: $color-white;
    padding: 0.2rem 0.5rem;
    margin-right: 0.2rem;
    border-radius: 3px;
    cursor: pointer;

    &:last-child {
      margin-right: 0;
    }

    &:hover {
      background-color: rgba($color-white, 0.1);
    }

    &.is-active {
      background-color: rgba($color-white, 0.2);
    }
  }

  &__form {
    display: flex;
    align-items: center;
  }

  &__input {
    font: inherit;
    border: none;
    background: transparent;
    color: $color-white;
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
