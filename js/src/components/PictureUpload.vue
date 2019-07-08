<template>
  <div class="root">
    <figure class="image is-128x128">
      <img class="is-rounded" v-bind:src="imageSrc">
      <div class="image-placeholder" v-if="!imageSrc"></div>
    </figure>

    <b-upload @input="onFileChanged">
      <a class="button is-primary">
        <b-icon icon="upload"></b-icon>
        <span>Click to upload</span>
      </a>
    </b-upload>
  </div>
</template>

<style scoped type="scss">
  .root {
    display: flex;
    align-items: center;
  }

  .image {
    margin-right: 30px;
  }

  .image-placeholder {
    background-color: grey;
    width: 100%;
    height: 100%;
    border-radius: 100%;
  }
</style>

<script lang="ts">
import { Component, Model, Vue, Watch } from 'vue-property-decorator';

@Component
export default class PictureUpload extends Vue {
  @Model('change', { type: File }) readonly pictureFile!: File;

  imageSrc: string | null = null;

  @Watch('pictureFile')
  onPictureFileChanged (val: File) {
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
