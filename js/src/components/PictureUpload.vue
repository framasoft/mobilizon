<template>
    <b-field class="file">
        <b-upload v-model="pictureFile" @input="onFileChanged">
            <a class="button is-primary">
                <b-icon icon="upload"></b-icon>
                <span>Click to upload</span>
            </a>
        </b-upload>
        <span class="file-name" v-if="pictureFile">
            {{ pictureFile.name }}
        </span>
    </b-field>
</template>

<script lang="ts">
import { Component, Vue } from 'vue-property-decorator';
import { IPictureUpload } from '@/types/picture.model';

@Component
export default class PictureUpload extends Vue {
  picture!: IPictureUpload;
  pictureFile: File|null = null;

  onFileChanged(file: File) {
    this.picture = { file, name: file.name, alt: '' };
    this.$emit('change', this.picture);
  }
}
</script>
