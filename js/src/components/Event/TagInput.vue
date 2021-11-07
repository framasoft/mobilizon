<template>
  <b-field :label-for="id">
    <template slot="label">
      {{ $t("Add some tags") }}
      <b-tooltip
        type="is-dark"
        :label="
          $t('You can add tags by hitting the Enter key or by adding a comma')
        "
      >
        <b-icon size="is-small" icon="help-circle-outline"></b-icon>
      </b-tooltip>
    </template>
    <b-taginput
      v-model="tagsStrings"
      :data="filteredTags"
      autocomplete
      :allow-new="true"
      :field="'title'"
      icon="label"
      maxlength="20"
      maxtags="10"
      :placeholder="$t('Eg: Stockholm, Dance, Chess…')"
      @typing="getFilteredTags"
      :id="id"
      dir="auto"
    >
    </b-taginput>
  </b-field>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import differenceBy from "lodash/differenceBy";
import { ITag } from "../../types/tag.model";
import { FILTER_TAGS } from "@/graphql/tags";

@Component({
  apollo: {
    tags: {
      query: FILTER_TAGS,
      variables() {
        return {
          filter: this.text,
        };
      },
    },
  },
})
export default class TagInput extends Vue {
  @Prop({ required: true }) value!: ITag[];

  tags!: ITag[];

  text = "";

  private static componentId = 0;

  created(): void {
    TagInput.componentId += 1;
  }

  get id(): string {
    return `tag-input-${TagInput.componentId}`;
  }

  async getFilteredTags(text: string): Promise<void> {
    this.text = text;
    await this.$apollo.queries.tags.refetch();
  }

  get filteredTags(): ITag[] {
    return differenceBy(this.tags, this.value, "id").filter(
      (option) =>
        option.title
          .toString()
          .toLowerCase()
          .indexOf(this.text.toLowerCase()) >= 0 ||
        option.slug.toString().toLowerCase().indexOf(this.text.toLowerCase()) >=
          0
    );
  }

  get tagsStrings(): string[] {
    return (this.value || []).map((tag: ITag) => tag.title);
  }

  set tagsStrings(tagsStrings: string[]) {
    const tagEntities = tagsStrings.map((tag: string | ITag) => {
      if (typeof tag !== "string") {
        return tag;
      }
      return { title: tag, slug: tag } as ITag;
    });
    this.$emit("input", tagEntities);
  }
}
</script>
