<template>
  <div class="root">
    <figure class="image" v-if="imageSrc">
      <img :src="imageSrc"  />
    </figure>
    <figure class="image is-128x128" v-else>
      <div class="image-placeholder">
        <span class="has-text-centered">{{ textFallback }}</span>
      </div>
    </figure>

    <b-upload @input="onFileChanged" :accept="accept">
      <a class="button is-primary">
        <b-icon icon="upload"></b-icon>
        <span>{{ $t('Click to upload') }}</span>
      </a>
    </b-upload>
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
</style>

<script lang="ts">
import { Component, Model, Prop, Vue, Watch } from 'vue-property-decorator';

@Component
export default class PictureUpload extends Vue {
  @Model('change', { type: File }) readonly pictureFile!: File;
  @Prop({ type: String, required: false, default: 'image/png,image/jpeg' }) accept;
  // @ts-ignore
  @Prop({ type: String, required: false, default() { return this.$t('Avatar'); } }) textFallback!: string;

  imageSrc: string | null = null;

  mounted() {
    this.updatePreview(this.pictureFile);
  }

  @Watch('pictureFile')
  onPictureFileChanged(val: File) {
    this.updatePreview(val);
  }

  onFileChanged(file: File) {
    this.$emit('change', file);

    this.updatePreview(file);
  }

  private updatePreview(file?: File) {
    if (file) {
      this.imageSrc = URL.createObjectURL(file);
      return;
    }

    this.imageSrc = null;
  }
}
</script>
