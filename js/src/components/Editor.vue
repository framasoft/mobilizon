<template>
  <div v-if="editor">
    <div
      class="editor"
      :class="{ mode_description: isDescriptionMode }"
      id="tiptab-editor"
      :data-actor-id="currentActor && currentActor.id"
    >
      <editor-menu-bar
        v-if="isDescriptionMode"
        :editor="editor"
        v-slot="{ commands, isActive, focused }"
      >
        <div class="menubar bar-is-hidden" :class="{ 'is-focused': focused }">
          <button
            class="menubar__button"
            :class="{ 'is-active': isActive.bold() }"
            @click="commands.bold"
            type="button"
          >
            <b-icon icon="format-bold" />
          </button>

          <button
            class="menubar__button"
            :class="{ 'is-active': isActive.italic() }"
            @click="commands.italic"
            type="button"
          >
            <b-icon icon="format-italic" />
          </button>

          <button
            class="menubar__button"
            :class="{ 'is-active': isActive.underline() }"
            @click="commands.underline"
            type="button"
          >
            <b-icon icon="format-underline" />
          </button>

          <button
            class="menubar__button"
            :class="{ 'is-active': isActive.heading({ level: 1 }) }"
            @click="commands.heading({ level: 1 })"
            type="button"
          >
            <b-icon icon="format-header-1" />
          </button>

          <button
            class="menubar__button"
            :class="{ 'is-active': isActive.heading({ level: 2 }) }"
            @click="commands.heading({ level: 2 })"
            type="button"
          >
            <b-icon icon="format-header-2" />
          </button>

          <button
            class="menubar__button"
            :class="{ 'is-active': isActive.heading({ level: 3 }) }"
            @click="commands.heading({ level: 3 })"
            type="button"
          >
            <b-icon icon="format-header-3" />
          </button>

          <button
            class="menubar__button"
            @click="showLinkMenu(commands.link, isActive.link())"
            :class="{ 'is-active': isActive.link() }"
            type="button"
          >
            <b-icon icon="link" />
          </button>

          <button class="menubar__button" @click="showImagePrompt(commands.image)" type="button">
            <b-icon icon="image" />
          </button>

          <button
            class="menubar__button"
            :class="{ 'is-active': isActive.bullet_list() }"
            @click="commands.bullet_list"
            type="button"
          >
            <b-icon icon="format-list-bulleted" />
          </button>

          <button
            class="menubar__button"
            :class="{ 'is-active': isActive.ordered_list() }"
            @click="commands.ordered_list"
            type="button"
          >
            <b-icon icon="format-list-numbered" />
          </button>

          <button
            class="menubar__button"
            :class="{ 'is-active': isActive.blockquote() }"
            @click="commands.blockquote"
            type="button"
          >
            <b-icon icon="format-quote-close" />
          </button>

          <button class="menubar__button" @click="commands.undo" type="button">
            <b-icon icon="undo" />
          </button>

          <button class="menubar__button" @click="commands.redo" type="button">
            <b-icon icon="redo" />
          </button>
        </div>
      </editor-menu-bar>

      <editor-menu-bubble
        v-if="isCommentMode"
        :editor="editor"
        :keep-in-bounds="true"
        v-slot="{ commands, isActive, menu }"
      >
        <div
          class="menububble"
          :class="{ 'is-active': menu.isActive }"
          :style="`left: ${menu.left}px; bottom: ${menu.bottom}px;`"
        >
          <button
            class="menububble__button"
            :class="{ 'is-active': isActive.bold() }"
            @click="commands.bold"
            type="button"
          >
            <b-icon icon="format-bold" />
            <span class="visually-hidden">{{ $t("Bold") }}</span>
          </button>

          <button
            class="menububble__button"
            :class="{ 'is-active': isActive.italic() }"
            @click="commands.italic"
            type="button"
          >
            <b-icon icon="format-italic" />
            <span class="visually-hidden">{{ $t("Italic") }}</span>
          </button>
        </div>
      </editor-menu-bubble>

      <editor-content class="editor__content" :editor="editor" />
    </div>
    <div class="suggestion-list" v-show="showSuggestions" ref="suggestions">
      <template v-if="hasResults">
        <div
          v-for="(actor, index) in filteredActors"
          :key="actor.id"
          class="suggestion-list__item"
          :class="{ 'is-selected': navigatedActorIndex === index }"
          @click="selectActor(actor)"
        >
          {{ actor.name }}
        </div>
      </template>
      <div v-else class="suggestion-list__item is-empty">{{ $t("No actors found") }}</div>
    </div>
  </div>
</template>

<script lang="ts">
import { Component, Prop, Vue, Watch } from "vue-property-decorator";
import { Editor, EditorContent, EditorMenuBar, EditorMenuBubble } from "tiptap";
import {
  Blockquote,
  HardBreak,
  Heading,
  OrderedList,
  BulletList,
  ListItem,
  TodoItem,
  TodoList,
  Bold,
  Code,
  Italic,
  Link,
  Underline,
  History,
  Placeholder,
  Mention,
} from "tiptap-extensions";
import tippy, { Instance } from "tippy.js";
import { SEARCH_PERSONS } from "../graphql/search";
import { Actor, IActor, IPerson } from "../types/actor";
import Image from "./Editor/Image";
import { UPLOAD_PICTURE } from "../graphql/upload";
import { listenFileUpload } from "../utils/upload";
import { CURRENT_ACTOR_CLIENT } from "../graphql/actor";
import { IComment } from "../types/comment.model";

@Component({
  components: { EditorContent, EditorMenuBar, EditorMenuBubble },
  apollo: {
    currentActor: {
      query: CURRENT_ACTOR_CLIENT,
    },
  },
})
export default class EditorComponent extends Vue {
  @Prop({ required: true }) value!: string;

  @Prop({ required: false, default: "description" }) mode!: string;

  currentActor!: IPerson;

  editor: Editor | null = null;

  /**
   * Editor Suggestions
   */
  query!: string | null;

  filteredActors: IActor[] = [];

  suggestionRange!: object | null;

  navigatedActorIndex = 0;

  popup!: Instance | null;

  get isDescriptionMode() {
    return this.mode === "description";
  }

  get isCommentMode() {
    return this.mode === "comment";
  }

  get hasResults() {
    return this.filteredActors.length;
  }

  get showSuggestions() {
    return this.query || this.hasResults;
  }

  // eslint-disable-next-line
  insertMention(obj: { range: any; attrs: any }) {
    console.log("initialize Mention");
  }

  observer!: MutationObserver | null;

  mounted() {
    this.editor = new Editor({
      extensions: [
        new Blockquote(),
        new BulletList(),
        new HardBreak(),
        new Heading({ levels: [1, 2, 3] }),
        new Mention({
          items: () => [],
          onEnter: ({
            items,
            query,
            range,
            command,
            virtualNode,
          }: {
            items: any;
            query: any;
            range: any;
            command: any;
            virtualNode: any;
          }) => {
            this.query = query;
            this.filteredActors = items;
            this.suggestionRange = range;
            this.renderPopup(virtualNode);
            // we save the command for inserting a selected mention
            // this allows us to call it inside of our custom popup
            // via keyboard navigation and on click
            this.insertMention = command;
          },
          /**
           * is called when a suggestion has changed
           */
          onChange: ({
            items,
            query,
            range,
            virtualNode,
          }: {
            items: any;
            query: any;
            range: any;
            virtualNode: any;
          }) => {
            this.query = query;
            this.filteredActors = items;
            this.suggestionRange = range;
            this.navigatedActorIndex = 0;
            this.renderPopup(virtualNode);
          },

          /**
           * is called when a suggestion is cancelled
           */
          onExit: () => {
            // reset all saved values
            this.query = null;
            this.filteredActors = [];
            this.suggestionRange = null;
            this.navigatedActorIndex = 0;
            this.destroyPopup();
          },

          /**
           * is called on every keyDown event while a suggestion is active
           */
          onKeyDown: ({ event }: { event: KeyboardEvent }) => {
            // pressing up arrow
            if (event.keyCode === 38) {
              this.upHandler();
              return true;
            }
            // pressing down arrow
            if (event.keyCode === 40) {
              this.downHandler();
              return true;
            }
            // pressing enter
            if (event.keyCode === 13) {
              this.enterHandler();
              return true;
            }
            return false;
          },
          onFilter: async (items: any, query: string) => {
            if (!query) {
              return items;
            }
            const result = await this.$apollo.query({
              query: SEARCH_PERSONS,
              variables: {
                searchText: query,
              },
            });
            // TODO: TipTap doesn't handle async for onFilter, hence the following line.
            this.filteredActors = result.data.searchPersons.elements;
            return this.filteredActors;
          },
        }),
        new ListItem(),
        new OrderedList(),
        new TodoItem(),
        new TodoList(),
        new Link(),
        new Bold(),
        new Code(),
        new Italic(),
        new Underline(),
        new History(),
        new Placeholder({
          emptyEditorClass: "is-empty",
          emptyNodeText: this.$t("Write something…") as string,
          showOnlyWhenEditable: false,
        }),
        new Image(),
      ],
      onUpdate: ({ getHTML }: { getHTML: Function }) => {
        this.$emit("input", getHTML());
      },
    });
    this.editor.setContent(this.value);
  }

  @Watch("value")
  onValueChanged(val: string) {
    if (!this.editor) return;
    if (val !== this.editor.getHTML()) {
      this.editor.setContent(val);
    }
  }

  showLinkMenu(command: Function, active: boolean): Function | undefined {
    if (!this.editor) return undefined;
    if (active) return command({ href: null });
    this.$buefy.dialog.prompt({
      message: this.$t("Enter the link URL") as string,
      inputAttrs: {
        type: "url",
      },
      trapFocus: true,
      onConfirm: (value) => {
        command({ href: value });
        if (!this.editor) return;
        this.editor.focus();
      },
    });
    return undefined;
  }

  upHandler() {
    this.navigatedActorIndex =
      (this.navigatedActorIndex + this.filteredActors.length - 1) % this.filteredActors.length;
  }

  /**
   * navigate to the next item
   * if it's the last item, navigate to the first one
   */
  downHandler() {
    this.navigatedActorIndex = (this.navigatedActorIndex + 1) % this.filteredActors.length;
  }

  enterHandler() {
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
  selectActor(actor: IActor) {
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
    this.editor.focus();
  }

  replyToComment(comment: IComment) {
    const actorModel = new Actor(comment.actor);
    if (!this.editor) return;
    this.editor.commands.mention({
      id: actorModel.id,
      label: actorModel.usernameWithDomain().substring(1),
    });
    this.editor.focus();
  }

  /**
   * renders a popup with suggestions
   * tiptap provides a virtualNode object for using popper.js (or tippy.js) for popups
   * @param node
   */
  renderPopup(node: any) {
    if (this.popup) {
      return;
    }
    this.popup = tippy(node, {
      content: this.$refs.suggestions as HTMLElement,
      trigger: "mouseenter",
      interactive: true,
      theme: "dark",
      placement: "top-start",
      inertia: true,
      duration: [400, 200],
      showOnInit: true,
      arrow: true,
      arrowType: "round",
    }) as Instance;
    // we have to update tippy whenever the DOM is updated
    if (MutationObserver) {
      this.observer = new MutationObserver(() => {
        if (this.popup != null && this.popup.popperInstance) {
          this.popup.popperInstance.scheduleUpdate();
        }
      });
      this.observer.observe(this.$refs.suggestions as HTMLElement, {
        childList: true,
        subtree: true,
        characterData: true,
      });
    }
  }

  destroyPopup() {
    if (this.popup) {
      this.popup.destroy();
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
  async showImagePrompt(command: Function) {
    const image = await listenFileUpload();
    const { data } = await this.$apollo.mutate({
      mutation: UPLOAD_PICTURE,
      variables: {
        file: image,
        name: image.name,
        actorId: this.currentActor.id,
      },
    });
    if (data.uploadPicture && data.uploadPicture.url) {
      command({ src: data.uploadPicture.url });
    }
  }

  beforeDestroy() {
    if (!this.editor) return;
    this.editor.destroy();
  }
}
</script>
<style lang="scss">
@import "@/variables.scss";

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

  &.mode_description {
    div.ProseMirror {
      min-height: 10rem;
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
        border-color: $primary;
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
.mention {
  background: rgba($color-black, 0.1);
  color: rgba($color-black, 0.6);
  font-size: 0.9rem;
  font-weight: bold;
  border-radius: 5px;
  padding: 0.2rem;
  white-space: nowrap;
  margin-right: 0.2rem;
}
.mention-suggestion {
  color: rgba($color-black, 0.6);
}

.mention .mention {
  background: initial;
  margin-right: 0;
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
}
.tippy-tooltip.dark-theme {
  background-color: $color-black;
  padding: 0;
  font-size: 1rem;
  text-align: inherit;
  color: $color-white;
  border-radius: 5px;
  .tippy-backdrop {
    display: none;
  }
  .tippy-roundarrow {
    fill: $color-black;
  }
  .tippy-popper[x-placement^="top"] & .tippy-arrow {
    border-top-color: $color-black;
  }
  .tippy-popper[x-placement^="bottom"] & .tippy-arrow {
    border-bottom-color: $color-black;
  }
  .tippy-popper[x-placement^="left"] & .tippy-arrow {
    border-left-color: $color-black;
  }
  .tippy-popper[x-placement^="right"] & .tippy-arrow {
    border-right-color: $color-black;
  }
}

.visually-hidden {
  display: none;
}
</style>
