<template>
  <div class="root">
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
        <span class="has-text-centered" v-else>{{ textFallback }}</span>
      </div>
    </figure>

    <div class="action-buttons">
      <p v-if="pictureFile" class="metadata">
        <span class="name" :title="pictureFile.name">{{
          pictureFile.name
        }}</span>
        <span class="size">({{ formatBytes(pictureFile.size) }})</span>
      </p>
      <p v-if="pictureTooBig" class="picture-too-big">
        {{
          $t(
            "The selected picture is too heavy. You need to select a file smaller than {size}.",
            { size: formatBytes(maxSize) }
          )
        }}
      </p>
      <b-field class="file is-primary">
        <b-upload @input="onFileChanged" :accept="accept" class="file-label">
          <span class="file-cta">
            <b-icon class="file-icon" icon="upload" />
            <span>{{ $t("Click to upload") }}</span>
          </span>
        </b-upload>
      </b-field>
      <b-button type="is-text" v-if="imageSrc" @click="removeOrClearPicture">
        {{ $t("Clear") }}
      </b-button>
    </div>
  </div>
</template>

<style scoped lang="scss">
.root {
  display: flex;
  align-items: center;
}

figure.image {
  margin-right: 30px;
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

.action-buttons {
  display: flex;
  flex-direction: column;

  .file {
    justify-content: center;
  }

  .metadata {
    display: inline-flex;

    .name {
      max-width: 200px;
      display: block;
      text-overflow: ellipsis;
      white-space: nowrap;
      overflow: hidden;
      margin-right: 5px;
    }
  }
}

.picture-too-big {
  color: $danger;
}
</style>

<script lang="ts">
import { IMedia } from "@/types/media.model";
import { Component, Model, Prop, Vue, Watch } from "vue-property-decorator";

@Component
export default class PictureUpload extends Vue {
  @Model("change", { type: File }) readonly pictureFile!: File;

  @Prop({ type: Object, required: false }) defaultImage!: IMedia;

  @Prop({
    type: String,
    required: false,
    default: "image/gif,image/png,image/jpeg,image/webp",
  })
  accept!: string;

  @Prop({
    type: String,
    required: false,
    default() {
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      return this.$t("Avatar");
    },
  })
  textFallback!: string;

  @Prop({ type: Number, required: false, default: 10_485_760 })
  maxSize!: number;

  file!: File | null;

  imagePreviewLoadingError = false;

  get pictureTooBig(): boolean {
    return this.pictureFile?.size > this.maxSize;
  }

  get imageSrc(): string | null {
    if (this.pictureFile !== undefined) {
      if (this.pictureFile === null) return null;
      try {
        return URL.createObjectURL(this.pictureFile);
      } catch (e) {
        console.error(e);
      }
    }
    return this.defaultImage ? this.defaultImage.url : null;
  }

  onFileChanged(file: File | null): void {
    this.$emit("change", file);

    this.file = file;
  }

  async removeOrClearPicture(): Promise<void> {
    this.onFileChanged(null);
  }

  @Watch("imageSrc")
  resetImageLoadingError(): void {
    this.imagePreviewLoadingError = false;
  }

  showImageLoadingError(): void {
    this.imagePreviewLoadingError = true;
  }

  // https://gist.github.com/zentala/1e6f72438796d74531803cc3833c039c
  formatBytes(bytes: number, decimals: number): string {
    if (bytes == 0) return "0 Bytes";
    const k = 1024,
      dm = decimals || 2,
      sizes = ["Bytes", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"],
      i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + " " + sizes[i];
  }
}
</script>
