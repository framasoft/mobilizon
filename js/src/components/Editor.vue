<template>
    <div class="editor">
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
    Placeholder
} from 'tiptap-extensions';

@Component({
  components: { EditorContent, EditorMenuBar, EditorMenuBubble },
})
export default class CreateEvent extends Vue {
  @Prop({ required: true }) value!: String;
  editor: Editor = null;
  linkUrl: string|null = null;
  linkMenuIsActive: boolean = false;

  mounted() {
    this.editor = new Editor({
      extensions: [
        new Blockquote(),
        new BulletList(),
        new HardBreak(),
        new Heading({ levels: [1, 2, 3] }),
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
        })
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

  showLinkMenu(attrs) {
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
                background: #fff;
                min-height: 10rem;

                &:focus {
                    border-color: #3273dc;
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

</style>
