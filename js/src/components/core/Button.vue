<template>
  <component
    :is="computedTag"
    class="button"
    v-bind="attrs"
    :type="computedTag === 'button' ? nativeType : undefined"
    :class="[
      size,
      type,
      //   {
      //     'is-rounded': rounded,
      //     'is-loading': loading,
      //     'is-outlined': outlined,
      //     'is-fullwidth': expanded,
      //     'is-inverted': inverted,
      //     'is-focused': focused,
      //     'is-active': active,
      //     'is-hovered': hovered,
      //     'is-selected': selected,
      //   },
    ]"
    v-on="attrs"
  >
    <!-- <o-icon
      v-if="iconLeft"
      :pack="iconPack"
      :icon="iconLeft"
      :size="iconSize"
    /> -->
    <span v-if="label">{{ label }}</span>
    <span v-else-if="$slots.default">
      <slot />
    </span>
    <!-- <o-icon
      v-if="iconRight"
      :pack="iconPack"
      :icon="iconRight"
      :size="iconSize"
    /> -->
  </component>
</template>

<script lang="ts" setup>
import { computed, useAttrs } from "vue";

const props = withDefaults(
  defineProps<{
    type?: string;
    size?: string;
    label?: string;
    nativeType?: "button" | "submit" | "reset";
    tag?: "button" | "a" | "router-link";
  }>(),
  { tag: "button" }
);

const attrs = useAttrs();

const computedTag = computed(() => {
  if (attrs.disabled !== undefined && attrs.disabled !== false) {
    return "button";
  }
  return props.tag;
});

const iconSize = computed(() => {
  if (!props.size || props.size === "is-medium") {
    return "is-small";
  } else if (props.size === "is-large") {
    return "is-medium";
  }
  return props.size;
});
</script>
