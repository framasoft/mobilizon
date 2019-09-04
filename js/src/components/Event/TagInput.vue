<template>
    <b-field label="Enter some tags">
        <b-taginput
                v-model="tagsStrings"
                :data="filteredTags"
                autocomplete
                :allow-new="true"
                :field="path"
                icon="label"
                placeholder="Add a tag"
                @typing="getFilteredTags"
        >
        </b-taginput>
    </b-field>
</template>
<script lang="ts">
import { Component, Prop, Vue } from 'vue-property-decorator';
import { get, differenceBy } from 'lodash';
import { ITag } from '@/types/tag.model';

@Component({
  computed: {
    tagsStrings: {
      get() {
        return this.$props.data.map((tag: ITag) => tag.title);
      },
      set(tagStrings) {
        const tagEntities = tagStrings.map((tag) => {
          if (TagInput.isTag(tag)) {
            return tag;
          }
          return { title: tag, slug: tag } as ITag;
        });
        this.$emit('input', tagEntities);
      },
    },
  },
})
export default class TagInput extends Vue {

  @Prop({ required: false, default: () => [] }) data!: ITag[];
  @Prop({ required: true, default: 'value' }) path!: string;
  @Prop({ required: true }) value!: ITag[];

  filteredTags: ITag[] = [];

  getFilteredTags(text) {
    this.filteredTags = differenceBy(this.data, this.value, 'id').filter((option) => {
      return get(option, this.path)
                .toString()
                .toLowerCase()
                .indexOf(text.toLowerCase()) >= 0;
    });
  }

  static isTag(x: any): x is ITag {
    return x.slug !== undefined;
  }
}
</script>
