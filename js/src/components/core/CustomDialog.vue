<template>
  <div class="">
    <header class="" v-if="title">
      <h2 class="">{{ title }}</h2>
    </header>

    <section :class="{ 'flex gap-1': hasIcon }">
      <div class="" v-if="hasIcon && (icon || iconByType)">
        <o-icon
          :icon="icon ? icon : iconByType"
          :variant="variant"
          :both="!icon"
          custom-size="48"
        />
      </div>
      <div class="">
        <p>
          <template v-if="$slots.default">
            <slot />
          </template>
          <template v-else>
            <div v-html="message" />
          </template>
        </p>

        <o-field v-if="hasInput">
          <o-input
            v-model="prompt"
            expanded
            class="input"
            ref="input"
            v-bind="inputAttrs"
            @keydown.enter="confirm"
          />
        </o-field>
      </div>
    </section>

    <footer v-if="canCancel" class="flex gap-2 my-2">
      <o-button ref="cancelButton" outlined @click="cancel('button')">{{
        cancelText ?? t("Cancel")
      }}</o-button>
      <o-button :variant="variant" ref="confirmButton" @click="confirm">{{
        confirmText ?? t("Confirm")
      }}</o-button>
    </footer>
  </div>
</template>

<script lang="ts" setup>
import { computed, nextTick, ref } from "vue";
import { useI18n } from "vue-i18n";

const props = withDefaults(
  defineProps<{
    title: string;
    message: string | string[];
    icon?: string;
    hasIcon?: boolean;
    variant?: string;
    size?: string;
    canCancel?: boolean;
    confirmText?: string;
    cancelText?: string;
    onConfirm: (prompt?: string) => any;
    onCancel?: (source: string) => any;
    ariaLabel?: string;
    ariaModal?: boolean;
    ariaRole?: string;
    hasInput?: boolean;
    inputAttrs?: Record<string, any>;
  }>(),
  {
    variant: "primary",
    canCancel: true,
    hasInput: false,
    inputAttrs: () => ({}),
  }
);

const emit = defineEmits(["confirm", "cancel", "close"]);

const { t } = useI18n({ useScope: "global" });

// const modalOpened = ref(false);

const prompt = ref<string>(props.hasInput ? props.inputAttrs?.value ?? "" : "");
const input = ref();

// const dialogClass = computed(() => {
//   return [props.size];
// });
/**
 * Icon name (MDI) based on the type.
 */
const iconByType = computed(() => {
  switch (props.variant) {
    case "info":
      return "information";
    case "success":
      return "check-circle";
    case "warning":
      return "alert";
    case "danger":
      return "alert-circle";
    default:
      return null;
  }
});
/**
 * If it's a prompt Dialog, validate the input.
 * Call the onConfirm prop (function) and close the Dialog.
 */
const confirm = () => {
  console.debug("dialog confirmed", input.value?.$el);
  if (input.value !== undefined) {
    const inputElement = input.value.$el.querySelector("input");
    if (!inputElement.checkValidity()) {
      nextTick(() => inputElement.select());
      return;
    }
  }
  emit("confirm", prompt.value);
  props.onConfirm(prompt.value);
  close();
};

/**
 * Close the Dialog.
 */
const close = () => {
  emit("close");
};

/**
 * Close the Modal if canCancel and call the onCancel prop (function).
 */
const cancel = (source: string) => {
  emit("cancel", source);
  if (props?.onCancel) {
    props?.onCancel(source);
  }
  close();
};
</script>
