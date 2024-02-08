<template>
  <div class="p-2">
    <header v-if="title" class="mb-3">
      <h2 class="text-2xl">{{ title }}</h2>
    </header>

    <section>
      <div
        class="flex gap-1 flex-row mb-3 bg-mbz-yellow dark:text-black p-3 rounded items-center"
      >
        <o-icon
          icon="alert"
          variant="warning"
          custom-size="48"
          class="hidden md:block flex-1"
        />
        <p>
          {{
            t(
              "The report will be sent to the moderators of your instance. You can explain why you report this content below."
            )
          }}
        </p>
      </div>
      <div>
        <article v-if="comment">
          <div>
            <figure class="h-8 w-8" v-if="comment?.actor?.avatar">
              <img
                :src="comment.actor.avatar.url"
                alt=""
                width="48"
                height="48"
              />
            </figure>
            <AccountCircle v-else :size="48" />
          </div>
          <div class="prose dark:prose-invert">
            <strong>{{ comment?.actor?.name }}</strong>
            <small v-if="comment.actor"
              >@{{ usernameWithDomain(comment?.actor) }}</small
            >
            <br />
            <p v-html="comment.text"></p>
          </div>
        </article>

        <o-field
          :label="t('Additional comments')"
          label-for="additional-comments"
        >
          <o-input
            v-model="content"
            type="textarea"
            id="additional-comments"
            autofocus
            ref="reportAdditionalCommentsInput"
            expanded
          />
        </o-field>

        <div class="control" v-if="outsideDomain">
          <p>
            {{
              t(
                "The content came from another server. Transfer an anonymous copy of the report?"
              )
            }}
          </p>
          <o-switch v-model="forward">{{
            t("Transfer to {outsideDomain}", { outsideDomain })
          }}</o-switch>
        </div>
      </div>
    </section>

    <footer class="flex gap-2 py-3">
      <o-button ref="cancelButton" outlined @click="close">
        {{ translatedCancelText }}
      </o-button>
      <o-button
        variant="primary"
        ref="confirmButton"
        @click="confirm"
        @keyup.enter="confirm"
      >
        {{ translatedConfirmText }}
      </o-button>
    </footer>
  </div>
</template>

<script lang="ts" setup>
import { computed, ref } from "vue";
import { useI18n } from "vue-i18n";
import { IComment } from "../../types/comment.model";
import { usernameWithDomain } from "@/types/actor";
import AccountCircle from "vue-material-design-icons/AccountCircle.vue";
import { useFocus } from "@vueuse/core";

const props = withDefaults(
  defineProps<{
    onConfirm: (content: string, forward: boolean) => void;
    title?: string;
    comment?: IComment;
    outsideDomain?: string | null;
    cancelText?: string;
    confirmText?: string;
  }>(),
  {
    outsideDomain: null,
  }
);

const emit = defineEmits(["close"]);

const content = ref("");

const forward = ref(false);

const reportAdditionalCommentsInput = ref();
// https://github.com/oruga-ui/oruga/issues/339
const reportAdditionalCommentsInputComp = computed(
  () => reportAdditionalCommentsInput.value?.$refs.textarea
);
useFocus(reportAdditionalCommentsInputComp, { initialValue: true });

const { t } = useI18n({ useScope: "global" });

const translatedCancelText = computed((): string => {
  return props.cancelText ?? (t("Cancel") as string);
});

const translatedConfirmText = computed((): string => {
  return props.confirmText ?? (t("Send the report") as string);
});

const confirm = (): void => {
  props.onConfirm(content.value, forward.value);
  close();
};

/**
 * Close the Dialog.
 */
const close = (): void => {
  // isActive = false;
  emit("close");
};
</script>
<style lang="scss" scoped>
.modal-card .modal-card-foot {
  justify-content: flex-end;
}

.modal-card-body {
  .media-content {
    .box {
      .media {
        padding-top: 0;
        border-top: none;
      }
    }

    & > p {
      margin-bottom: 2rem;
    }
  }
}
</style>
