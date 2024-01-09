<template>
  <div v-if="editor !== null">
    <div
      class="editor"
      :class="{ short_mode: isShortMode, comment_mode: isCommentMode }"
      id="tiptab-editor"
      :data-actor-id="currentActor && currentActor.id"
    >
      <div
        class="mb-2 menubar bar-is-hidden"
        v-if="isDescriptionMode"
        :editor="editor"
      >
        <button
          class="menubar__button"
          :class="{ 'is-active': editor?.isActive('bold') }"
          @click="editor?.chain().focus().toggleBold().run()"
          type="button"
          :title="t('Bold')"
        >
          <FormatBold :size="24" />
        </button>

        <button
          class="menubar__button"
          :class="{ 'is-active': editor?.isActive('italic') }"
          @click="editor?.chain().focus().toggleItalic().run()"
          type="button"
          :title="t('Italic')"
        >
          <FormatItalic :size="24" />
        </button>

        <button
          class="menubar__button"
          :class="{ 'is-active': editor?.isActive('underline') }"
          @click="editor?.chain().focus().toggleUnderline().run()"
          type="button"
          :title="t('Underline')"
        >
          <FormatUnderline :size="24" />
        </button>

        <button
          v-if="!isBasicMode"
          class="menubar__button"
          :class="{
            'is-active': editor?.isActive('heading', {
              level: props.headingLevel[0],
            }),
          }"
          @click="
            editor
              ?.chain()
              .focus()
              .toggleHeading({ level: props.headingLevel[0] })
              .run()
          "
          type="button"
          :title="t('Heading Level 1')"
        >
          <FormatHeader1 :size="24" />
        </button>

        <button
          v-if="!isBasicMode"
          class="menubar__button"
          :class="{
            'is-active': editor?.isActive('heading', {
              level: props.headingLevel[1],
            }),
          }"
          @click="
            editor
              ?.chain()
              .focus()
              .toggleHeading({ level: props.headingLevel[1] })
              .run()
          "
          type="button"
          :title="t('Heading Level 2')"
        >
          <FormatHeader2 :size="24" />
        </button>

        <button
          v-if="!isBasicMode"
          class="menubar__button"
          :class="{
            'is-active': editor?.isActive('heading', {
              level: props.headingLevel[2],
            }),
          }"
          @click="
            editor
              ?.chain()
              .focus()
              .toggleHeading({ level: props.headingLevel[2] })
              .run()
          "
          type="button"
          :title="t('Heading Level 3')"
        >
          <FormatHeader3 :size="24" />
        </button>

        <button
          class="menubar__button"
          @click="showLinkMenu()"
          :class="{ 'is-active': editor?.isActive('link') }"
          type="button"
          :title="t('Add link')"
        >
          <LinkIcon :size="24" />
        </button>

        <button
          v-if="editor?.isActive('link')"
          class="menubar__button"
          @click="editor?.chain().focus().unsetLink().run()"
          type="button"
          :title="t('Remove link')"
        >
          <LinkOff :size="24" />
        </button>

        <button
          class="menubar__button"
          v-if="!isBasicMode"
          @click="showImagePrompt()"
          type="button"
          :title="t('Add picture')"
        >
          <Image :size="24" />
        </button>

        <button
          class="menubar__button"
          v-if="!isBasicMode"
          :class="{ 'is-active': editor?.isActive('bulletList') }"
          @click="editor?.chain().focus().toggleBulletList().run()"
          type="button"
          :title="t('Bullet list')"
        >
          <FormatListBulleted :size="24" />
        </button>

        <button
          v-if="!isBasicMode"
          class="menubar__button"
          :class="{ 'is-active': editor?.isActive('orderedList') }"
          @click="editor?.chain().focus().toggleOrderedList().run()"
          type="button"
          :title="t('Ordered list')"
        >
          <FormatListNumbered :size="24" />
        </button>

        <button
          v-if="!isBasicMode"
          class="menubar__button"
          :class="{ 'is-active': editor?.isActive('blockquote') }"
          @click="editor?.chain().focus().toggleBlockquote().run()"
          type="button"
          :title="t('Quote')"
        >
          <FormatQuoteClose :size="24" />
        </button>

        <button
          v-if="!isBasicMode"
          class="menubar__button"
          @click="editor?.chain().focus().undo().run()"
          type="button"
          :title="t('Undo')"
        >
          <Undo :size="24" />
        </button>

        <button
          v-if="!isBasicMode"
          class="menubar__button"
          @click="editor?.chain().focus().redo().run()"
          type="button"
          :title="t('Redo')"
        >
          <Redo :size="24" />
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
          :title="t('Bold')"
        >
          <FormatBold :size="24" />
          <span class="visually-hidden">{{ t("Bold") }}</span>
        </button>

        <button
          class="menububble__button"
          :class="{ 'is-active': editor.isActive('italic') }"
          @click="editor?.chain().focus().toggleItalic().run()"
          type="button"
          :title="t('Italic')"
        >
          <FormatItalic :size="24" />
          <span class="visually-hidden">{{ t("Italic") }}</span>
        </button>
      </bubble-menu>

      <editor-content
        class="editor__content"
        :class="{ editorErrorStatus }"
        :editor="editor"
        v-if="editor"
      />
      <p v-if="editorErrorMessage" class="text-sm text-mbz-danger">
        {{ editorErrorMessage }}
      </p>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { useEditor, EditorContent, BubbleMenu } from "@tiptap/vue-3";
import Blockquote from "@tiptap/extension-blockquote";
import BulletList from "@tiptap/extension-bullet-list";
import Heading, { Level } from "@tiptap/extension-heading";
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
import RichEditorKeyboardSubmit from "./Editor/RichEditorKeyboardSubmit";
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
import { computed, inject, onBeforeUnmount, ref, watch } from "vue";
import { Dialog } from "@/plugins/dialog";
import { useI18n } from "vue-i18n";
import { useMutation } from "@vue/apollo-composable";
import { Notifier } from "@/plugins/notifier";
import FormatBold from "vue-material-design-icons/FormatBold.vue";
import FormatItalic from "vue-material-design-icons/FormatItalic.vue";
import FormatUnderline from "vue-material-design-icons/FormatUnderline.vue";
import FormatHeader1 from "vue-material-design-icons/FormatHeader1.vue";
import FormatHeader2 from "vue-material-design-icons/FormatHeader2.vue";
import FormatHeader3 from "vue-material-design-icons/FormatHeader3.vue";
import LinkIcon from "vue-material-design-icons/Link.vue";
import LinkOff from "vue-material-design-icons/LinkOff.vue";
import Image from "vue-material-design-icons/Image.vue";
import FormatListBulleted from "vue-material-design-icons/FormatListBulleted.vue";
import FormatListNumbered from "vue-material-design-icons/FormatListNumbered.vue";
import FormatQuoteClose from "vue-material-design-icons/FormatQuoteClose.vue";
import Undo from "vue-material-design-icons/Undo.vue";
import Redo from "vue-material-design-icons/Redo.vue";
import Placeholder from "@tiptap/extension-placeholder";

const props = withDefaults(
  defineProps<{
    modelValue: string;
    mode?: "description" | "comment" | "basic";
    maxSize?: number;
    ariaLabel?: string;
    currentActor: IPerson;
    placeholder?: string;
    headingLevel?: Level[];
    required?: boolean;
  }>(),
  {
    mode: "description",
    maxSize: 100_000_000,
    headingLevel: () => [3, 4, 5],
    required: false,
  }
);

const emit = defineEmits(["update:modelValue", "submit"]);

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

const ariaLabel = computed(() => props.ariaLabel);
const headingLevel = computed(() => props.headingLevel);
const placeholder = computed(() => props.placeholder);
const value = computed(() => props.modelValue);

const { t } = useI18n({ useScope: "global" });

const editor = useEditor({
  editorProps: {
    attributes: {
      "aria-multiline": isShortMode.value.toString(),
      "aria-label": ariaLabel.value ?? "",
      role: "textbox",
      class:
        "prose dark:prose-invert prose-sm lg:prose-lg xl:prose-xl bg-white dark:bg-zinc-700 focus:outline-none !max-w-full",
    },
    transformPastedHTML: transformPastedHTML,
  },
  extensions: [
    Blockquote,
    BulletList,
    Heading.configure({
      levels: headingLevel.value,
    }),
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
    RichEditorKeyboardSubmit.configure({
      submit: () => emit("submit"),
    }),
    Placeholder.configure({
      placeholder: placeholder.value ?? t("Write something"),
    }),
  ],
  injectCSS: false,
  content: value.value,
  onUpdate: () => {
    emit("update:modelValue", editor.value?.getHTML());
  },
  onBlur: () => {
    checkEditorEmpty();
  },
  onFocus: () => {
    editorErrorStatus.value = false;
    editorErrorMessage.value = "";
  },
});

watch(value, (val: string) => {
  if (!editor.value) return;
  if (val !== editor.value.getHTML()) {
    editor.value.commands.setContent(val, false);
  }
});

const dialog = inject<Dialog>("dialog");

/**
 * Show a popup to get the link from the URL
 */
const showLinkMenu = (): void => {
  dialog?.prompt({
    message: t("Enter the link URL"),
    hasInput: true,
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
        alt: "",
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

const editorErrorStatus = ref(false);
const editorErrorMessage = ref("");

const isEmpty = computed(
  () => props.required === true && editor.value?.isEmpty === true
);

const checkEditorEmpty = () => {
  editorErrorStatus.value = isEmpty.value;
  editorErrorMessage.value = isEmpty.value ? t("You need to enter a text") : "";
};
</script>
<style lang="scss">
@use "@/styles/_mixins" as *;
@import "./Editor/style.scss";

.menubar {
  transition:
    visibility 0.2s 0.4s,
    opacity 0.2s 0.4s;

  &__button {
    font-weight: bold;
    display: inline-flex;
    background: transparent;
    border: 0;
    padding: 0.2rem 0.5rem;
    // @include margin-right(0.2rem);
    border-radius: 3px;
    cursor: pointer;
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
      border-radius: 4px;
      padding: 12px 6px;

      &:focus {
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
  padding: 0;
  font-size: 1rem;
  text-align: inherit;
  border-radius: 5px;
}

.visually-hidden {
  display: none;
}

.ProseMirror p.is-editor-empty:first-child::before {
  content: attr(data-placeholder);
  float: left;
  color: #adb5bd;
  pointer-events: none;
  height: 0;
}
</style>
<style>
.menubar__button {
  @apply mx-0.5;
}

.menubar__button.is-active {
  @apply bg-zinc-300 dark:bg-zinc-500;
}

.mention[data-id] {
  @apply inline-block border border-zinc-600 dark:border-zinc-300 rounded py-0.5 px-1;
}

.editor__content {
  @apply border focus:border-[#2563eb] rounded border-[#6b7280];
}

.editorErrorStatus {
  @apply border-red-500;
}
.editor__content p.is-editor-empty:first-child::before {
  @apply text-slate-300;
}
</style>
