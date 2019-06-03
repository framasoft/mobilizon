<template>
    <div>
    <div class="editor" id="tiptab-editor" :data-actor-id="loggedPerson && loggedPerson.id">
        <editor-menu-bar :editor="editor" v-slot="{ commands, isActive, focused }">
            <div class="menubar bar-is-hidden" :class="{ 'is-focused': focused }">

                <button
                        class="menubar__button"
                        :class="{ 'is-active': isActive.bold() }"
                        @click="commands.bold"
                >
                    <b-icon icon="format-bold" />
                </button>

                <button
                        class="menubar__button"
                        :class="{ 'is-active': isActive.italic() }"
                        @click="commands.italic"
                >
                    <b-icon icon="format-italic" />
                </button>

                <button
                        class="menubar__button"
                        :class="{ 'is-active': isActive.underline() }"
                        @click="commands.underline"
                >
                    <b-icon icon="format-underline" />
                </button>

                <button
                        class="menubar__button"
                        :class="{ 'is-active': isActive.heading({ level: 1 }) }"
                        @click="commands.heading({ level: 1 })"
                >
                    <b-icon icon="format-header-1" />
                </button>

                <button
                        class="menubar__button"
                        :class="{ 'is-active': isActive.heading({ level: 2 }) }"
                        @click="commands.heading({ level: 2 })"
                >
                    <b-icon icon="format-header-2" />
                </button>

                <button
                        class="menubar__button"
                        :class="{ 'is-active': isActive.heading({ level: 3 }) }"
                        @click="commands.heading({ level: 3 })"
                >
                    <b-icon icon="format-header-3" />
                </button>

                <button
                        class="menubar__button"
                        @click="showImagePrompt(commands.image)"
                >
                    <b-icon icon="image" />
                </button>

                <button
                        class="menubar__button"
                        :class="{ 'is-active': isActive.bullet_list() }"
                        @click="commands.bullet_list"
                >
                    <b-icon icon="format-list-bulleted" />
                </button>

                <button
                        class="menubar__button"
                        :class="{ 'is-active': isActive.ordered_list() }"
                        @click="commands.ordered_list"
                >
                    <b-icon icon="format-list-numbered" />
                </button>

                <button
                        class="menubar__button"
                        :class="{ 'is-active': isActive.blockquote() }"
                        @click="commands.blockquote"
                >
                    <b-icon icon="format-quote-close" />
                </button>

                <button
                        class="menubar__button"
                        @click="commands.undo"
                >
                    <b-icon icon="undo" />
                </button>

                <button
                        class="menubar__button"
                        @click="commands.redo"
                >
                    <b-icon icon="redo" />
                </button>

            </div>
        </editor-menu-bar>

        <editor-menu-bubble class="menububble" :editor="editor" @hide="hideLinkMenu" v-slot="{ commands, isActive, getMarkAttrs, menu }">
            <div
                    class="menububble"
                    :class="{ 'is-active': menu.isActive }"
                    :style="`left: ${menu.left}px; bottom: ${menu.bottom}px;`"
            >

                <form class="menububble__form" v-if="linkMenuIsActive" @submit.prevent="setLinkUrl(commands.link, linkUrl)">
                    <input class="menububble__input" type="text" v-model="linkUrl" placeholder="https://" ref="linkInput" @keydown.esc="hideLinkMenu"/>
                    <button class="menububble__button" @click="setLinkUrl(commands.link, null)" type="button">
                        <b-icon icon="delete" />
                    </button>
                </form>

                <template v-else>
                    <button
                            class="menububble__button"
                            @click="showLinkMenu(getMarkAttrs('link'))"
                            :class="{ 'is-active': isActive.link() }"
                    >
                        <span>{{ isActive.link() ? 'Update Link' : 'Add Link'}}</span>
                        <b-icon icon="link" />
                    </button>
                </template>

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
                        :class="{ 'is-selected': navigatedUserIndex === index }"
                        @click="selectActor(actor)"
                >
                    {{ actor.name }}
                </div>
            </template>
            <div v-else class="suggestion-list__item is-empty">
                No actors found
            </div>
        </div>
    </div>
</template>

<script lang="ts">
import { Component, Prop, Vue, Watch } from 'vue-property-decorator';
import { Editor, EditorContent, EditorMenuBar, EditorMenuBubble } from 'tiptap';
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
} from 'tiptap-extensions';
import tippy, { Instance } from 'tippy.js';
import { SEARCH_PERSONS } from '@/graphql/search';
import { IActor, IPerson } from '@/types/actor';
import Image from '@/components/Editor/Image';
import { UPLOAD_PICTURE } from '@/graphql/upload';
import { listenFileUpload } from '@/utils/upload';
import { LOGGED_PERSON } from '@/graphql/actor';

@Component({
  components: { EditorContent, EditorMenuBar, EditorMenuBubble },
  apollo: {
    loggedPerson: {
      query: LOGGED_PERSON,
    },
  },
})
export default class CreateEvent extends Vue {
  @Prop({ required: true }) value!: String;

  loggedPerson!: IPerson;

  editor: Editor = null;

    /**
     * Editor Link
     */
  linkUrl!: string|null;
  linkMenuIsActive: boolean = false;

    /**
     * Editor Suggestions
     */
  query!: string|null;
  filteredActors: IActor[] = [];
  suggestionRange!: object|null;
  navigatedUserIndex: number = 0;
  popup!: Instance|null;

  get hasResults() {
    return this.filteredActors.length;
  }
  get showSuggestions() {
    return this.query || this.hasResults;
  }

  insertMention: Function = () => {};
  observer!: MutationObserver|null;


  mounted() {
    this.editor = new Editor({
      extensions: [
        new Blockquote(),
        new BulletList(),
        new HardBreak(),
        new Heading({ levels: [1, 2, 3] }),
        new Mention({
          items: () => [],
          onEnter: ({ items, query, range, command, virtualNode }) => {
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
          onChange: ({ items, query, range, virtualNode }) => {
            this.query = query;
            this.filteredActors = items;
            this.suggestionRange = range;
            this.navigatedUserIndex = 0;
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
            this.navigatedUserIndex = 0;
            this.destroyPopup();
          },

          /**
           * is called on every keyDown event while a suggestion is active
           */
          onKeyDown: ({ event }) => {
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
          onFilter: async (items, query) => {
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
          emptyClass: 'is-empty',
          emptyNodeText: 'Write something …',
          showOnlyWhenEditable: false,
        }),
        new Image(),
      ],
      onUpdate: ({ getHTML }) => {
        this.$emit('input', getHTML());
      },
    });
    this.editor.setContent(this.value);
  }

  @Watch('value')
  onValueChanged(val: string) {
    if (val !== this.editor.getHTML()) {
      this.editor.setContent(val);
    }
  }

  showLinkMenu(attrs: any) {
    this.linkUrl = attrs.href;
    this.linkMenuIsActive = true;
    this.$nextTick(() => {
      const linkInput = this.$refs.linkInput as HTMLElement;
      linkInput.focus();
    });
  }
  hideLinkMenu() {
    this.linkUrl = '';
    this.linkMenuIsActive = false;
  }
  setLinkUrl(command, url: string) {
    command({ href: url });
    this.hideLinkMenu();
    this.editor.focus();
  }

  upHandler() {
    this.navigatedUserIndex = ((this.navigatedUserIndex + this.filteredActors.length) - 1) % this.filteredActors.length;
  }

  /**
   * navigate to the next item
   * if it's the last item, navigate to the first one
   */
  downHandler() {
    this.navigatedUserIndex = (this.navigatedUserIndex + 1) % this.filteredActors.length;
  }

  enterHandler() {
    const actor = this.filteredActors[this.navigatedUserIndex];
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
    this.insertMention({
      range: this.suggestionRange,
      attrs: {
        id: actor.id,
        label: actor.name,
      },
    });
    this.editor.focus();
  }

  /**
   * renders a popup with suggestions
   * tiptap provides a virtualNode object for using popper.js (or tippy.js) for popups
   * @param node
   */
  renderPopup(node) {
    if (this.popup) {
      return;
    }
    this.popup = tippy(node, {
      content: this.$refs.suggestions as HTMLElement,
      trigger: 'mouseenter',
      interactive: true,
      theme: 'dark',
      placement: 'top-start',
      inertia: true,
      duration: [400, 200],
      showOnInit: true,
      arrow: true,
      arrowType: 'round',
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
  async showImagePrompt(command) {
    const image = await listenFileUpload();
    const { data } = await this.$apollo.mutate({
      mutation: UPLOAD_PICTURE,
      variables: {
        file: image,
        name: image.name,
        actorId: this.loggedPerson.id,
      },
    });
    if (data.uploadPicture && data.uploadPicture.url) {
      command({ src: data.uploadPicture.url });
    }
  }

  beforeDestroy() {
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

        &.bar-is-hidden {
            visibility: hidden;
            opacity: 0;
        }

        &.is-focused {
            visibility: visible;
            opacity: 1;
            height: auto;
            transition: visibility 0.2s, opacity 0.2s;
        }

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
        max-width: 30rem;
        margin: 0 0 1rem;

        p.is-empty:first-child::before {
            content: attr(data-empty-text);
            float: left;
            color: #aaa;
            pointer-events: none;
            height: 0;
            font-style: italic;
        }

        &__content {
            div.ProseMirror {
                min-height: 10rem;

                &:focus {
                    border-color: #3273dc;
                    background: #fff;
                    box-shadow: 0 0 0 0.125em rgba(50, 115, 220, 0.25);
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
                list-style-type: disc;
            }

            li > p,
            li > ol,
            li > ul {
                margin: 0;
            }

            a {
                color: inherit;
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
        font-size: 0.8rem;
        font-weight: bold;
        border-radius: 5px;
        padding: 0.2rem 0.5rem;
        white-space: nowrap;
    }
    .mention-suggestion {
        color: rgba($color-black, 0.6);
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
        .tippy-popper[x-placement^=top] & .tippy-arrow {
            border-top-color: $color-black;
        }
        .tippy-popper[x-placement^=bottom] & .tippy-arrow {
            border-bottom-color: $color-black;
        }
        .tippy-popper[x-placement^=left] & .tippy-arrow {
            border-left-color: $color-black;
        }
        .tippy-popper[x-placement^=right] & .tippy-arrow {
            border-right-color: $color-black;
        }
    }

</style>
