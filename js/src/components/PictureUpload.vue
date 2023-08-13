<template>
  <div>
    <o-upload
      rootClass="!flex"
      v-if="!imageSrc || imagePreviewLoadingError || pictureTooBig"
      @update:modelValue="onFileChanged"
      :accept="accept"
      drag-drop
    >
      <div
        class="w-100 rounded text-center p-4 rounded-xl border-dashed border-2 border-gray-600"
      >
        <span class="mx-auto flex w-fit">
          <Upload />
          <span class="capitalize"
            >{{ $t("Click to upload") }} {{ textFallbackWithDefault }}</span
          >
        </span>
        <p v-if="pictureTooBig" class="text-mbz-danger">
          {{
            $t(
              "The selected picture is too heavy. You need to select a file smaller than {size}.",
              { size: formatBytes(maxSize) }
            )
          }}
        </p>
        <span
          class="has-text-centered text-mbz-danger"
          v-if="imagePreviewLoadingError"
          >{{ $t("Error while loading the preview") }}</span
        >
      </div>
    </o-upload>
  </div>

  <div
    v-if="
      imageSrc &&
      !imagePreviewLoadingError &&
      !pictureTooBig &&
      !imagePreviewLoadingError
    "
  >
    <figure
      class="w-fit relative image mx-auto my-4"
      v-if="imageSrc && !imagePreviewLoadingError"
    >
      <img
        class="max-h-52 rounded-xl"
        :src="imageSrc"
        @error="showImageLoadingError"
      />
      <o-button
        class="!absolute right-1 bottom-1"
        variant="danger"
        v-if="imageSrc"
        @click="removeOrClearPicture"
        @keyup.enter="removeOrClearPicture"
      >
        {{ $t("Clear") }}
      </o-button>
    </figure>
  </div>
</template>

<style scoped lang="scss">
@use "@/styles/_mixins" as *;
figure.image {
  // @include margin-right(30px);
  //max-height: 200px;
  //max-width: 200px;
  //overflow: hidden;
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
import { formatBytes } from "@/utils/datetime";

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
</script>
