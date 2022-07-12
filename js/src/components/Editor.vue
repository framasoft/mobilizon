<template>
  <div v-if="editor !== null">
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
          @click="editor?.chain().focus().toggleBold().run()"
          type="button"
          :title="$t('Bold')"
        >
          <o-icon icon="format-bold" />
        </button>

        <button
          class="menubar__button"
          :class="{ 'is-active': editor.isActive('italic') }"
          @click="editor?.chain().focus().toggleItalic().run()"
          type="button"
          :title="$t('Italic')"
        >
          <o-icon icon="format-italic" />
        </button>

        <button
          class="menubar__button"
          :class="{ 'is-active': editor.isActive('underline') }"
          @click="editor?.chain().focus().toggleUnderline().run()"
          type="button"
          :title="$t('Underline')"
        >
          <o-icon icon="format-underline" />
        </button>

        <button
          v-if="!isBasicMode"
          class="menubar__button"
          :class="{ 'is-active': editor.isActive('heading', { level: 1 }) }"
          @click="editor?.chain().focus().toggleHeading({ level: 1 }).run()"
          type="button"
          :title="$t('Heading Level 1')"
        >
          <o-icon icon="format-header-1" />
        </button>

        <button
          v-if="!isBasicMode"
          class="menubar__button"
          :class="{ 'is-active': editor.isActive('heading', { level: 2 }) }"
          @click="editor?.chain().focus().toggleHeading({ level: 2 }).run()"
          type="button"
          :title="$t('Heading Level 2')"
        >
          <o-icon icon="format-header-2" />
        </button>

        <button
          v-if="!isBasicMode"
          class="menubar__button"
          :class="{ 'is-active': editor.isActive('heading', { level: 3 }) }"
          @click="editor?.chain().focus().toggleHeading({ level: 3 }).run()"
          type="button"
          :title="$t('Heading Level 3')"
        >
          <o-icon icon="format-header-3" />
        </button>

        <button
          class="menubar__button"
          @click="showLinkMenu()"
          :class="{ 'is-active': editor.isActive('link') }"
          type="button"
          :title="$t('Add link')"
        >
          <o-icon icon="link" />
        </button>

        <button
          v-if="editor.isActive('link')"
          class="menubar__button"
          @click="editor?.chain().focus().unsetLink().run()"
          type="button"
          :title="$t('Remove link')"
        >
          <o-icon icon="link-off" />
        </button>

        <button
          class="menubar__button"
          v-if="!isBasicMode"
          @click="showImagePrompt()"
          type="button"
          :title="$t('Add picture')"
        >
          <o-icon icon="image" />
        </button>

        <button
          class="menubar__button"
          v-if="!isBasicMode"
          :class="{ 'is-active': editor.isActive('bulletList') }"
          @click="editor?.chain().focus().toggleBulletList().run()"
          type="button"
          :title="$t('Bullet list')"
        >
          <o-icon icon="format-list-bulleted" />
        </button>

        <button
          v-if="!isBasicMode"
          class="menubar__button"
          :class="{ 'is-active': editor.isActive('orderedList') }"
          @click="editor?.chain().focus().toggleOrderedList().run()"
          type="button"
          :title="$t('Ordered list')"
        >
          <o-icon icon="format-list-numbered" />
        </button>

        <button
          v-if="!isBasicMode"
          class="menubar__button"
          :class="{ 'is-active': editor.isActive('blockquote') }"
          @click="editor?.chain().focus().toggleBlockquote().run()"
          type="button"
          :title="$t('Quote')"
        >
          <o-icon icon="format-quote-close" />
        </button>

        <button
          v-if="!isBasicMode"
          class="menubar__button"
          @click="editor?.chain().focus().undo().run()"
          type="button"
          :title="$t('Undo')"
        >
          <o-icon icon="undo" />
        </button>

        <button
          v-if="!isBasicMode"
          class="menubar__button"
          @click="editor?.chain().focus().redo().run()"
          type="button"
          :title="$t('Redo')"
        >
          <o-icon icon="redo" />
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
          @click="editor?.chain().focus().toggleBold().run()"
          type="button"
          :title="$t('Bold')"
        >
          <o-icon icon="format-bold" />
          <span class="visually-hidden">{{ $t("Bold") }}</span>
        </button>

        <button
          class="menububble__button"
          :class="{ 'is-active': editor.isActive('italic') }"
          @click="editor?.chain().focus().toggleItalic().run()"
          type="button"
          :title="$t('Italic')"
        >
          <o-icon icon="format-italic" />
          <span class="visually-hidden">{{ $t("Italic") }}</span>
        </button>
      </bubble-menu>

      <editor-content class="editor__content" :editor="editor" v-if="editor" />
    </div>
  </div>
</template>

<script lang="ts" setup>
import { Editor, EditorContent, BubbleMenu } from "@tiptap/vue-3";
import Blockquote from "@tiptap/extension-blockquote";
import BulletList from "@tiptap/extension-bullet-list";
import Heading from "@tiptap/extension-heading";
import Document from "@tiptap/extension-document";
import Paragraph from "@tiptap/extension-paragraph";
import Bold from "@tiptap/extension-bold";
import Italic from "@tiptap/extension-italic";
import Strike from "@tiptap/extension-strike";
import Text from "@tiptap/extension-text";
import Dropcursor from "@tiptap/extension-dropcursor";
import Gapcursor from "@tiptap/extension-gapcursor";
import History from "@tiptap/extension-history";
import { IActor, IPerson, usernameWithDomain } from "../types/actor";
import CustomImage from "./Editor/Image";
import { UPLOAD_MEDIA } from "../graphql/upload";
import { listenFileUpload } from "../utils/upload";
import Mention from "@tiptap/extension-mention";
import MentionOptions from "./Editor/Mention";
import OrderedList from "@tiptap/extension-ordered-list";
import ListItem from "@tiptap/extension-list-item";
import Underline from "@tiptap/extension-underline";
import Link from "@tiptap/extension-link";
import { AutoDir } from "./Editor/Autodir";
// import sanitizeHtml from "sanitize-html";
import { computed, inject, onBeforeUnmount, onMounted, ref, watch } from "vue";
import { Dialog } from "@/plugins/dialog";
import { useI18n } from "vue-i18n";
import { useMutation } from "@vue/apollo-composable";
import { Notifier } from "@/plugins/notifier";

const props = withDefaults(
  defineProps<{
    modelValue: string;
    mode?: string;
    maxSize?: number;
    ariaLabel?: string;
    currentActor: IPerson;
  }>(),
  {
    mode: "description",
    maxSize: 100_000_000,
  }
);

const emit = defineEmits(["update:modelValue"]);

const editor = ref<Editor | null>(null);

const isDescriptionMode = computed((): boolean => {
  return props.mode === "description" || isBasicMode.value;
});

const isCommentMode = computed((): boolean => {
  return props.mode === "comment";
});

const isShortMode = computed((): boolean => {
  return isBasicMode.value;
});

const isBasicMode = computed((): boolean => {
  return props.mode === "basic";
});

const insertMention = (obj: { range: any; attrs: any }) => {
  console.log("initialize Mention");
};

const observer = ref<MutationObserver | null>(null);

onMounted(() => {
  editor.value = new Editor({
    editorProps: {
      attributes: {
        "aria-multiline": isShortMode.value.toString(),
        "aria-label": props.ariaLabel ?? "",
        role: "textbox",
      },
      transformPastedHTML: transformPastedHTML,
    },
    extensions: [
      Blockquote,
      BulletList,
      Heading,
      Document,
      Paragraph,
      Text,
      OrderedList,
      ListItem,
      Mention.configure(MentionOptions),
      CustomImage,
      AutoDir,
      Underline,
      Bold,
      Italic,
      Strike,
      Dropcursor,
      Gapcursor,
      History,
      Link.configure({
        HTMLAttributes: { target: "_blank", rel: "noopener noreferrer ugc" },
      }),
    ],
    injectCSS: false,
    content: props.modelValue,
    onUpdate: () => {
      emit("update:modelValue", editor.value?.getHTML());
    },
  });
});

const transformPastedHTML = (html: string): string => {
  // When using comment mode, limit to acceptable tags
  if (isCommentMode.value) {
    // return sanitizeHtml(html, {
    //   allowedTags: ["b", "i", "em", "strong", "a"],
    //   allowedAttributes: {
    //     a: ["href", "rel", "target"],
    //   },
    // });
    return html;
  }
  return html;
};

const value = computed(() => props.modelValue);

watch(value, (val: string) => {
  if (!editor.value) return;
  if (val !== editor.value.getHTML()) {
    editor.value.commands.setContent(val, false);
  }
});

const dialog = inject<Dialog>("dialog");
const { t } = useI18n({ useScope: "global" });

/**
 * Show a popup to get the link from the URL
 */
const showLinkMenu = (): void => {
  dialog?.prompt({
    message: t("Enter the link URL"),
    inputAttrs: {
      type: "url",
    },
    onConfirm: (prompt: string) => {
      if (!editor.value) return;
      editor.value.chain().focus().setLink({ href: prompt }).run();
    },
  });
};

const {
  mutate: uploadMediaMutation,
  onDone: uploadMediaDone,
  onError: uploadMediaError,
} = useMutation(UPLOAD_MEDIA);

/**
 * Show a file prompt, upload picture and insert it into editor
 */
const showImagePrompt = async (): Promise<void> => {
  const image = await listenFileUpload();
  uploadMediaMutation({
    file: image,
    name: image.name,
  });
};

uploadMediaDone(({ data }) => {
  if (data.uploadMedia && data.uploadMedia.url && editor.value) {
    editor.value
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
});

const notifier = inject<Notifier>("notifier");

uploadMediaError((error) => {
  console.error(error);
  if (error.graphQLErrors && error.graphQLErrors.length > 0) {
    notifier?.error(error.graphQLErrors[0].message);
  }
});

/**
 * We use this to programatically insert an actor mention when creating a reply to comment
 */
const replyToComment = (actor: IActor): void => {
  if (!editor.value) return;
  editor.value
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
};

const focus = (): void => {
  editor.value?.chain().focus("end");
};

defineExpose({ replyToComment, focus });

onBeforeUnmount(() => {
  editor.value?.destroy();
});
</script>
<style lang="scss">
@use "@/styles/_mixins" as *;
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
    // @include margin-right(0.2rem);
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

    // ul,
    // ol {
    //   @include padding-left(1rem);
    // }

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
      // @include padding-left(0.8rem);
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
