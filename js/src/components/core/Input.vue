<template>
  <div class="control" :class="rootClasses">
    <input
      v-if="type !== 'textarea'"
      ref="input"
      class="input"
      :class="[inputClasses, customClass]"
      :type="newType"
      :autocomplete="autocomplete"
      :maxlength="maxLength"
      :value="computedValue"
      v-bind="$attrs"
      @input="onInput"
      @blur="onBlur"
      @focus="onFocus"
    />

    <textarea
      v-else
      ref="textarea"
      class="textarea"
      :class="[inputClasses, customClass]"
      :maxlength="maxLength"
      :value="computedValue"
      v-bind="$attrs"
      @input="onInput"
      @blur="onBlur"
      @focus="onFocus"
    />

    <!-- <o-icon
      v-if="icon"
      class="is-left"
      :icon="icon"
      :size="iconSize"
      @click.native="emit('icon-click', $event)"
    />

    <o-icon
      v-if="!loading && hasIconRight"
      class="is-right"
      :class="{ 'is-clickable': passwordReveal }"
      :icon="rightIcon"
      :size="iconSize"
      :type="rightIconType"
      both
      @click.native="rightIconClick"
    /> -->

    <small
      v-if="maxLength && hasCounter && type !== 'number'"
      class="help counter"
      :class="{ 'is-invisible': !isFocused }"
    >
      {{ valueLength }} / {{ maxLength }}
    </small>
  </div>
</template>
<script setup lang="ts">
import { computed, nextTick, ref, watch } from "vue";

const props = withDefaults(
  defineProps<{
    icon?: string;
    modelValue: number | string;
    size?: string;
    type?: string;
    passwordReveal?: boolean;
    iconRight?: string;
    rounded?: boolean;
    loading?: boolean;
    customClass?: string;
    maxLength?: number | string;
    hasCounter?: boolean;
    autocomplete?: "on" | "off";
    statusType?: string;
  }>(),
  {
    type: "text",
    rounded: false,
    loading: false,
    customClass: "",
    hasCounter: false,
    autocomplete: "on",
  }
);

const emit = defineEmits(["update:modelValue", "icon-click", "blur", "focus"]);

const newValue = ref(props.modelValue);
const newType = ref(props.type);
const isPasswordVisible = ref(false);
const isValid = ref(true);
const isFocused = ref(false);

const computedValue = computed({
  get() {
    return newValue.value;
  },
  set(value) {
    newValue.value = value;
    emit("update:modelValue", value);
  },
});

const rootClasses = computed(() => {
  return [
    iconPosition,
    props.size,
    // {
    //     'is-expanded': this.expanded,
    //     'is-loading': this.loading,
    //     'is-clearfix': !this.hasMessage
    // }
  ];
});
const inputClasses = computed(() => {
  return [props.statusType, props.size, { "is-rounded": props.rounded }];
});

const hasIconRight = computed(() => {
  return (
    props.passwordReveal || props.loading || statusTypeIcon || props.iconRight
  );
});
const rightIcon = computed(() => {
  if (props.passwordReveal) {
    return passwordVisibleIcon;
  } else if (props.iconRight) {
    return props.iconRight;
  }
  return statusTypeIcon;
});
const rightIconType = computed(() => {
  if (props.passwordReveal) {
    return "is-primary";
  }
});
/**
 * Position of the icon or if it's both sides.
 */
const iconPosition = computed(() => {
  let iconClasses = "";
  if (props.icon) {
    iconClasses += "has-icons-left ";
  }
  if (hasIconRight.value) {
    iconClasses += "has-icons-right";
  }
  return iconClasses;
});
/**
 * Icon name (MDI) based on the type.
 */
const statusTypeIcon = computed(() => {
  switch (props.statusType) {
    case "is-success":
      return "check";
    case "is-danger":
      return "alert-circle";
    case "is-info":
      return "information";
    case "is-warning":
      return "alert";
  }
});
/**
 * Current password-reveal icon name.
 */
const passwordVisibleIcon = computed(() => {
  return !isPasswordVisible.value ? "eye" : "eye-off";
});
/**
 * Get value length
 */
const valueLength = computed(() => {
  if (typeof computedValue.value === "string") {
    return Array.from(computedValue.value).length;
  } else if (typeof computedValue.value === "number") {
    return computedValue.value.toString().length;
  }
  return 0;
});

/**
 * Fix icon size for inputs, large was too big
 */
const iconSize = computed(() => {
  switch (props.size) {
    case "is-small":
      return props.size;
    case "is-medium":
      return;
    case "is-large":
      return "is-medium";
  }
});

watch(props, () => {
  newValue.value = props.modelValue;
});

/**
 * Toggle the visibility of a password-reveal input
 * by changing the type and focus the input right away.
 */
const togglePasswordVisibility = async () => {
  isPasswordVisible.value = !isPasswordVisible.value;
  newType.value = isPasswordVisible.value ? "text" : "password";
  await nextTick();
  await focus();
};
const rightIconClick = (event: Event) => {
  if (props.passwordReveal) {
    togglePasswordVisibility();
  }
};
const onInput = (event: Event) => {
  const value = event.target?.value;
  updateValue(value);
};
const updateValue = (value: string) => {
  computedValue.value = value;
  !isValid.value && checkHtml5Validity();
};

/**
 * Check HTML5 validation, set isValid property.
 * If validation fail, send 'is-danger' type,
 * and error message to parent if it's a Field.
 */
const checkHtml5Validity = () => {
  const el = getElement();
  if (el === undefined) return;

  if (!el.value?.checkValidity()) {
    // setInvalid();
    isValid.value = false;
  } else {
    // setValidity(null, null);
    isValid.value = true;
  }

  return isValid.value;
};

// const setInvalid = () => {
//   let type = "is-danger";
//   let message = validationMessage || getElement().validationMessage;
//   setValidity(type, message);
// };

// const setValidity = async (type, message) => {
//   await nextTick();
//   if (this.parentField) {
//     // Set type only if not defined
//     if (!this.parentField.type) {
//       this.parentField.newType = type;
//     }
//     // Set message only if not defined
//     if (!this.parentField.message) {
//       this.parentField.newMessage = message;
//     }
//   }
// };

const input = ref<HTMLInputElement | null>(null);
const textarea = ref<HTMLInputElement | null>(null);

const getElement = () => {
  return props.type === "input" ? input : textarea;
};

const focus = async () => {
  const el = getElement();
  if (el.value === undefined) return;

  await nextTick();
  if (el.value) el.value?.focus();
};

const onBlur = ($event: FocusEvent) => {
  isFocused.value = false;
  emit("blur", $event);
  checkHtml5Validity();
};

const onFocus = ($event: FocusEvent) => {
  isFocused.value = true;
  emit("focus", $event);
};
</script>
