<template>
  <div
    class="block p-4 bg-white rounded-lg border border-gray-200 shadow-md hover:bg-gray-100 dark:bg-gray-800 dark:border-gray-700 dark:hover:bg-gray-700"
  >
    <div class="flex flex-wrap gap-1 w-full items-center">
      <div class="">
        <img
          v-if="
            modelValue.icon && modelValue.icon.substring(0, 7) === 'mz:icon'
          "
          :src="`/img/${modelValue.icon.substring(8)}_monochrome.svg`"
          width="24"
          height="24"
          alt=""
        />

        <o-icon
          v-else-if="modelValue.icon"
          :icon="modelValue.icon"
          customSize="24"
        />
        <o-icon v-else icon="help-circle" customSize="24" />
      </div>
      <div class="flex-1">
        <b>{{ modelValue.title || modelValue.label }}</b>
        <br />
        <small>
          {{ modelValue.description }}
        </small>
        <div
          v-if="
            modelValue.type === EventMetadataType.STRING &&
            modelValue.keyType === EventMetadataKeyType.CHOICE &&
            modelValue.choices
          "
        >
          <o-field v-for="(value, key) in modelValue.choices" :key="key">
            <o-radio v-model="metadataItemValue" :native-value="key">{{
              value
            }}</o-radio>
          </o-field>
        </div>
        <o-field
          v-else-if="
            modelValue.type === EventMetadataType.STRING &&
            modelValue.keyType == EventMetadataKeyType.URL
          "
        >
          <o-input
            @blur="validatePattern"
            ref="urlInput"
            type="url"
            :pattern="
              modelValue.pattern ? modelValue.pattern.source : undefined
            "
            :validation-message="t(`This URL doesn't seem to be valid`)"
            required
            v-model="metadataItemValue"
            :placeholder="modelValue.placeholder"
          />
        </o-field>
        <o-field v-else-if="modelValue.type === EventMetadataType.STRING">
          <o-input
            v-model="metadataItemValue"
            :placeholder="modelValue.placeholder"
          />
        </o-field>
        <o-field v-else-if="modelValue.type === EventMetadataType.INTEGER">
          <o-input type="number" v-model="metadataItemValue" />
        </o-field>
        <o-field v-else-if="modelValue.type === EventMetadataType.BOOLEAN">
          <o-checkbox v-model="metadataItemValue">
            {{
              metadataItemValue === "true"
                ? modelValue?.choices?.true
                : modelValue?.choices?.false
            }}
          </o-checkbox>
        </o-field>
      </div>
      <o-button icon-left="close" @click="$emit('removeItem', modelValue.key)">
        <span class="sr-only">
          {{ t("Remove") }}
        </span>
      </o-button>
    </div>
  </div>
</template>
<script lang="ts" setup>
import { EventMetadataKeyType, EventMetadataType } from "@/types/enums";
import { IEventMetadataDescription } from "@/types/event-metadata";
import { computed, ref } from "vue";
import { useI18n } from "vue-i18n";

const props = defineProps<{
  modelValue: IEventMetadataDescription;
}>();

const emit = defineEmits(["update:modelValue", "removeItem"]);

const { t } = useI18n({ useScope: "global" });

const urlInput = ref<any>(null);

const metadataItemValue = computed({
  get(): string {
    return props.modelValue.value;
  },
  set(value: string) {
    if (validate(value)) {
      emit("update:modelValue", {
        ...props.modelValue,
        value: value.toString(),
      });
    }
  },
});

const validatePattern = (): void => {
  urlInput.value?.checkHtml5Validity();
};

const validate = (value: string): boolean => {
  if (props.modelValue.keyType === EventMetadataKeyType.URL) {
    try {
      const url = new URL(value);
      if (!["http:", "https:", "mailto:"].includes(url.protocol)) return false;
      if (props.modelValue.pattern) {
        return value.match(props.modelValue.pattern) !== null;
      }
    } catch {
      return false;
    }
  }
  return true;
};
</script>
<style lang="scss" scoped>
@use "@/styles/_mixins" as *;
.card .media {
  align-items: center;

  // & > button {
  //   @include margin-left(1rem);
  // }
}
</style>
