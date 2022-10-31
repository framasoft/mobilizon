<template>
  <article class="flex gap-2 bg-white dark:bg-transparent">
    <div class="">
      <figure class="" v-if="comment.actor && comment.actor.avatar">
        <img
          class="rounded-xl"
          :src="comment.actor.avatar.url"
          alt=""
          :width="48"
          :height="48"
        />
      </figure>
      <AccountCircle :size="48" v-else />
    </div>
    <div class="mb-2 pt-1 flex-1">
      <div class="flex items-center gap-1" dir="auto">
        <div
          class="flex flex-1 flex-col"
          v-if="comment.actor && !comment.deletedAt"
        >
          <strong v-if="comment.actor.name">{{ comment.actor.name }}</strong>
          <small>@{{ usernameWithDomain(comment.actor) }}</small>
        </div>
        <span v-else class="name comment-link has-text-grey">
          {{ t("[deleted]") }}
        </span>
        <span
          class="icons"
          v-if="
            comment.actor &&
            !comment.deletedAt &&
            comment.actor.id === currentActor?.id
          "
        >
          <o-dropdown aria-role="list" position="bottom-left">
            <template #trigger>
              <o-icon role="button" icon="dots-horizontal" />
            </template>

            <o-dropdown-item
              v-if="comment.actor?.id === currentActor?.id"
              @click="toggleEditMode"
              aria-role="menuitem"
            >
              <o-icon icon="pencil"></o-icon>
              {{ t("Edit") }}
            </o-dropdown-item>
            <o-dropdown-item
              v-if="comment.actor?.id === currentActor?.id"
              @click="emit('deleteComment', comment)"
              aria-role="menuitem"
            >
              <o-icon icon="delete"></o-icon>
              {{ t("Delete") }}
            </o-dropdown-item>
            <!-- <o-dropdown-item aria-role="listitem" @click="isReportModalActive = true">
              <o-icon icon="flag" />
              {{ t("Report") }}
            </o-dropdown-item> -->
          </o-dropdown>
        </span>
        <div class="self-center">
          <span
            :title="formatDateTimeString(comment.updatedAt?.toString())"
            v-if="comment.updatedAt"
          >
            {{
              formatDistanceToNow(new Date(comment.updatedAt?.toString()), {
                locale: dateFnsLocale,
              }) || t("Right now")
            }}</span
          >
        </div>
      </div>
      <div
        v-if="!editMode && !comment.deletedAt"
        class="text-wrapper"
        dir="auto"
      >
        <div
          class="prose md:prose-lg lg:prose-xl dark:prose-invert"
          v-html="comment.text"
        ></div>
        <p
          class="text-sm"
          v-if="
            comment.insertedAt &&
            comment.updatedAt &&
            new Date(comment.insertedAt).getTime() !==
              new Date(comment.updatedAt).getTime()
          "
          :title="formatDateTimeString(comment.updatedAt.toString())"
        >
          {{
            t("Edited {ago}", {
              ago: formatDistanceToNow(new Date(comment.updatedAt), {
                locale: dateFnsLocale,
              }),
            })
          }}
        </p>
      </div>
      <div class="comment-deleted" v-else-if="!editMode">
        {{ t("[This comment has been deleted by it's author]") }}
      </div>
      <form v-else class="edition" @submit.prevent="updateComment">
        <Editor
          v-model="updatedComment"
          :aria-label="t('Comment body')"
          :current-actor="currentActor"
          :placeholder="t('Write a new message')"
        />
        <div class="flex gap-2 mt-2">
          <o-button
            native-type="submit"
            :disabled="['<p></p>', '', comment.text].includes(updatedComment)"
            variant="primary"
            >{{ t("Update") }}</o-button
          >
          <o-button native-type="button" @click="toggleEditMode">{{
            t("Cancel")
          }}</o-button>
        </div>
      </form>
    </div>
  </article>
</template>
<script lang="ts" setup>
import { formatDistanceToNow } from "date-fns";
import { IComment } from "../../types/comment.model";
import { IPerson, usernameWithDomain } from "../../types/actor";
import { computed, defineAsyncComponent, inject, ref } from "vue";
import { formatDateTimeString } from "@/filters/datetime";
import AccountCircle from "vue-material-design-icons/AccountCircle.vue";
import type { Locale } from "date-fns";
import { useI18n } from "vue-i18n";

const Editor = defineAsyncComponent(
  () => import("@/components/TextEditor.vue")
);

const props = defineProps<{
  modelValue: IComment;
  currentActor: IPerson;
}>();

const emit = defineEmits(["update:modelValue", "deleteComment"]);

const { t } = useI18n({ useScope: "global" });

const comment = computed(() => props.modelValue);

const editMode = ref(false);

const updatedComment = ref("");

const dateFnsLocale = inject<Locale>("dateFnsLocale");

// isReportModalActive: boolean = false;

const toggleEditMode = (): void => {
  updatedComment.value = comment.value.text;
  editMode.value = !editMode.value;
};

const updateComment = (): void => {
  emit("update:modelValue", {
    ...comment.value,
    text: updatedComment.value,
  });
  toggleEditMode();
};
</script>
<style lang="scss" scoped>
@use "@/styles/_mixins" as *;
article.comment {
  display: flex;
  border-top: 1px solid #e9e9e9;

  div.body {
    flex: 2;
    margin-bottom: 2rem;
    padding-top: 1rem;

    .meta {
      display: flex;
      align-items: center;
      padding: 0 1rem 0.3em;

      .name {
        // @include margin-right(auto);
        flex: 1 1 auto;
        overflow: hidden;

        strong {
          display: block;
          line-height: 1rem;
        }
      }

      .icons {
        display: inline;
        cursor: pointer;
      }
    }

    .text-wrapper,
    .comment-deleted {
      padding: 0 1rem;

      & > p {
        font-size: 0.85rem;
        font-style: italic;
      }

      div.description-content {
        padding-bottom: 0.3rem;

        :deep(h1) {
          font-size: 2rem;
        }

        :deep(h2) {
          font-size: 1.5rem;
        }

        :deep(h3) {
          font-size: 1.25rem;
        }

        :deep(ul) {
          list-style-type: disc;
        }

        :deep(li) {
          margin: 10px auto 10px 2rem;
        }

        :deep(blockquote) {
          border-left: 0.2em solid #333;
          display: block;
          // @include padding-left(1em);
        }

        :deep(p) {
          margin: 10px auto;

          a {
            display: inline-block;
            padding: 0.3rem;
            color: #111;

            &:empty {
              display: none;
            }
          }
        }
      }
    }
  }

  div.avatar {
    padding-top: 1rem;
    flex: 0;
  }

  .edition {
    .button {
      margin-top: 0.75rem;
    }
  }
}
</style>
