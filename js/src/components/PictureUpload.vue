<template>
  <div class="flex items-center">
    <figure class="image" v-if="imageSrc && !imagePreviewLoadingError">
      <img :src="imageSrc" @error="showImageLoadingError" />
    </figure>
    <figure class="image is-128x128" v-else>
      <div
        class="image-placeholder"
        :class="{ error: imagePreviewLoadingError }"
      >
        <span class="has-text-centered" v-if="imagePreviewLoadingError">{{
          $t("Error while loading the preview")
        }}</span>
        <span class="has-text-centered" v-else>{{
          textFallbackWithDefault
        }}</span>
      </div>
    </figure>

    <div class="flex flex-col">
      <p v-if="modelValue" class="inline-flex">
        <span class="block truncate max-w-[200px]" :title="modelValue.name">{{
          modelValue.name
        }}</span>
        <span>({{ formatBytes(modelValue.size) }})</span>
      </p>
      <p v-if="pictureTooBig" class="text-mbz-danger">
        {{
          $t(
            "The selected picture is too heavy. You need to select a file smaller than {size}.",
            { size: formatBytes(maxSize) }
          )
        }}
      </p>
      <o-field class="justify-center" variant="primary">
        <o-upload @update:modelValue="onFileChanged" :accept="accept" drag-drop>
          <span>
            <Upload />
            <span>{{ $t("Click to upload") }}</span>
          </span>
        </o-upload>
      </o-field>
      <o-button
        type="is-text"
        v-if="imageSrc"
        @click="removeOrClearPicture"
        @keyup.enter="removeOrClearPicture"
      >
        {{ $t("Clear") }}
      </o-button>
    </div>
  </div>
</template>

<style scoped lang="scss">
@use "@/styles/_mixins" as *;
figure.image {
  // @include margin-right(30px);
  max-height: 200px;
  max-width: 200px;
  overflow: hidden;
}

.image-placeholder {
  background-color: grey;
  width: 100%;
  height: 100%;
  border-radius: 100%;
  display: flex;
  justify-content: center;
  align-items: center;

  &.error {
    border: 2px solid red;
  }

  span {
    flex: 1;
    color: #eee;
  }
}
</style>

<script lang="ts" setup>
import { IMedia } from "@/types/media.model";
import { computed, ref, watch } from "vue";
import { useI18n } from "vue-i18n";
import Upload from "vue-material-design-icons/Upload.vue";

const { t } = useI18n({ useScope: "global" });

const props = withDefaults(
  defineProps<{
    modelValue: File | null;
    defaultImage?: IMedia | null;
    accept?: string;
    textFallback?: string;
    maxSize?: number;
  }>(),
  {
    accept: "image/gif,image/png,image/jpeg,image/webp",
    maxSize: 10_485_760,
  }
);

const textFallbackWithDefault = props.textFallback ?? t("Avatar");

const emit = defineEmits(["update:modelValue"]);

const imagePreviewLoadingError = ref(false);

const pictureTooBig = computed((): boolean => {
  return props.modelValue != null && props.modelValue?.size > props.maxSize;
});

const imageSrc = computed((): string | null | undefined => {
  if (props.modelValue !== undefined) {
    if (props.modelValue === null) return null;
    try {
      return URL.createObjectURL(props.modelValue);
    } catch (e) {
      console.error(e, props.modelValue);
    }
  }
  return props.defaultImage?.url;
});

const onFileChanged = (file: File | null): void => {
  emit("update:modelValue", file);
};

const removeOrClearPicture = async (): Promise<void> => {
  onFileChanged(null);
};

watch(imageSrc, () => {
  imagePreviewLoadingError.value = false;
});

const showImageLoadingError = (): void => {
  imagePreviewLoadingError.value = true;
};

// https://gist.github.com/zentala/1e6f72438796d74531803cc3833c039c
const formatBytes = (bytes: number, decimals?: number): string => {
  if (bytes == 0) return "0 Bytes";
  const k = 1024,
    dm = decimals || 2,
    sizes = ["Bytes", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"],
    i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + " " + sizes[i];
};
</script>
