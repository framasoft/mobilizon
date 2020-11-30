<template>
  <div class="root">
    <figure class="image" v-if="imageSrc">
      <img :src="imageSrc" />
    </figure>
    <figure class="image is-128x128" v-else>
      <div class="image-placeholder">
        <span class="has-text-centered">{{ textFallback }}</span>
      </div>
    </figure>

    <div class="action-buttons">
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

  span {
    flex: 1;
    color: #eee;
  }
}

.action-buttons {
  display: flex;
  flex-direction: column;
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

  imageSrc: string | null = this.defaultImage ? this.defaultImage.url : null;

  file!: File | null;

  mounted(): void {
    if (this.pictureFile) {
      this.updatePreview(this.pictureFile);
    }
  }

  @Watch("pictureFile")
  onPictureFileChanged(val: File): void {
    this.updatePreview(val);
  }

  @Watch("defaultImage")
  onDefaultImageChange(defaultImage: IMedia): void {
    this.imageSrc = defaultImage ? defaultImage.url : null;
  }

  onFileChanged(file: File | null): void {
    this.$emit("change", file);

    this.updatePreview(file);
    this.file = file;
  }

  async removeOrClearPicture(): Promise<void> {
    this.onFileChanged(null);
  }

  private updatePreview(file?: File | null) {
    if (file) {
      this.imageSrc = URL.createObjectURL(file);
      return;
    }

    this.imageSrc = null;
  }
}
</script>
