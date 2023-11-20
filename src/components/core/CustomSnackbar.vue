<template>
  <transition enter-active-class="fadeInUp" leave-active-class="fadeOut">
    <div
      v-show="isActive"
      class="snackbar"
      :class="[variant, position]"
      @mouseenter="pause"
      @mouseleave="removePause"
      :role="actionTextWithDefault ? 'alertdialog' : 'alert'"
    >
      <template v-if="$slots.default">
        <slot />
      </template>
      <template v-else>
        <div class="text" v-html="message" />
      </template>
      <div class="flex gap-2">
        <div v-if="cancelText" class="action light cancel" @click="close">
          <o-button>{{ cancelText }}</o-button>
        </div>
        <div
          v-if="actionTextWithDefault"
          class="action"
          @click="action"
          :class="variant"
        >
          <o-button>{{ actionTextWithDefault }}</o-button>
        </div>
      </div>
    </div>
  </transition>
</template>
<script lang="ts" setup>
import { computed, onMounted, ref } from "vue";
import { useI18n } from "vue-i18n";

type positionValues =
  | "top-right"
  | "top"
  | "top-left"
  | "bottom-right"
  | "bottom"
  | "bottom-left";

const props = withDefaults(
  defineProps<{
    message: string;
    actionText?: string;
    onAction?: () => any;
    cancelText?: string | null;
    variant?: string;
    position?: positionValues;
    pauseOnHover?: boolean;
    indefinite?: boolean;
  }>(),
  {
    onAction: () => {
      // do nothing
    },
    cancelText: null,
    variant: "dark",
    position: "bottom-right",
    pauseOnHover: false,
    indefinite: false,
  }
);

const emit = defineEmits(["close"]);

const { t } = useI18n({ useScope: "global" });

const actionTextWithDefault = computed(() => props.actionText ?? t("OK"));

const isActive = ref(false);
const isPaused = ref(false);
const timer = ref(0);

onMounted(() => {
  isActive.value = true;
});

const pause = () => {
  isPaused.value = true;
};

const removePause = () => {
  if (props.pauseOnHover && !props.indefinite) {
    isPaused.value = false;
    close();
  }
};

const action = () => {
  props.onAction();
};

const close = () => {
  if (!isPaused.value) {
    clearTimeout(timer.value);
    isActive.value = false;
    emit("close");
  }
};
</script>
