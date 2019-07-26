<template>
    <b-field label="Enter some tags">
        <b-taginput
                v-model="tags"
                :data="filteredTags"
                autocomplete
                :allow-new="true"
                :field="path"
                icon="label"
                placeholder="Add a tag"
                @typing="getFilteredTags">
        </b-taginput>
    </b-field>
</template>
<script lang="ts">
import { Component, Prop, Vue, Watch } from 'vue-property-decorator';
import { get } from 'lodash';
import { ITag } from '@/types/tag.model';
@Component
export default class TagInput extends Vue {

  @Prop({ required: false, default: () => [] }) data!: object[];
  @Prop({ required: true, default: 'value' }) path!: string;
  @Prop({ required: true }) value!: string;

  filteredTags: object[] = [];
  tags: object[] = [];

  getFilteredTags(text) {
    this.filteredTags = this.data.filter((option) => {
      return get(option, this.path)
                .toString()
                .toLowerCase()
                .indexOf(text.toLowerCase()) >= 0;
    });
  }

  @Watch('tags')
  onTagsChanged (tags) {
    const tagEntities = tags.map((tag) => {
      if (TagInput.isTag(tag)) {
        return tag;
      }
      return { title: tag, slug: tag } as ITag;
    });
    console.log('tags changed', tagEntities);
    this.$emit('input', tagEntities);
  }

  static isTag(x: any): x is ITag {
    return x.slug !== undefined;
  }
}
</script>
