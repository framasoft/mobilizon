<template>
  <div v-if="attached && closable" class="tags has-addons">
    <span class="tag" :class="[type, size, { 'is-rounded': rounded }]">
      <!-- <o-icon
        v-if="icon"
        :icon="icon"
        :size="size"
        :type="iconType"
      /> -->
      <span :class="{ 'has-ellipsis': ellipsis }" @click="click">
        <slot />
      </span>
    </span>
    <a
      class="tag"
      role="button"
      :aria-label="ariaCloseLabel"
      :tabindex="tabstop ? 0 : false"
      :disabled="disabled"
      :class="[
        size,
        closeType,
        { 'is-rounded': rounded },
        closeIcon ? 'has-delete-icon' : 'is-delete',
      ]"
      @click="close"
      @keyup.delete.prevent="close"
    >
      <!-- <o-icon
        custom-class=""
        v-if="closeIcon"
        :icon="closeIcon"
        :size="size"
        :type="closeIconType"
      /> -->
    </a>
  </div>
  <span v-else class="tag" :class="[type, size, { 'is-rounded': rounded }]">
    <!-- <o-icon
      v-if="icon"
      :icon="icon"
      :size="size"
      :type="iconType"
    /> -->
    <span :class="{ 'has-ellipsis': ellipsis }" @click="click">
      <slot />
    </span>

    <a
      v-if="closable"
      role="button"
      :aria-label="ariaCloseLabel"
      class="delete is-small"
      :class="closeType"
      :disabled="disabled"
      :tabindex="tabstop ? 0 : false"
      @click="close"
      @keyup.delete.prevent="close"
    />
  </span>
</template>
<script setup lang="ts">
const props = withDefaults(
  defineProps<{
    attached?: boolean;
    closable?: boolean;
    type?: string;
    size?: string;
    rounded?: boolean;
    disabled?: boolean;
    ellipsis?: boolean;
    tabstop?: boolean;
    ariaCloseLabel?: string;
    icon?: string;
    iconType?: string;
    closeType?: string;
    closeIcon?: string;
    closeIconType?: string;
  }>(),
  {
    tabstop: true,
  }
);

const emit = defineEmits(["close", "click"]);

/**
 * Emit close event when delete button is clicked
 * or delete key is pressed.
 */
const close = (event: Event) => {
  if (props.disabled) return;
  emit("close", event);
};
/**
 * Emit click event when tag is clicked.
 */
const click = (event: Event) => {
  if (props.disabled) return;
  emit("click", event);
};
</script>
