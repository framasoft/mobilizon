<template>
  <b-field>
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
      :field="path"
      icon="label"
      maxlength="20"
      maxtags="10"
      :placeholder="$t('Eg: Stockholm, Dance, Chess…')"
      @typing="getFilteredTags"
    >
    </b-taginput>
  </b-field>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { get, differenceBy } from "lodash";
import { ITag } from "../../types/tag.model";

@Component({
  computed: {
    tagsStrings: {
      get() {
        return this.$props.value.map((tag: ITag) => tag.title);
      },
      set(tagStrings) {
        const tagEntities = tagStrings.map((tag: string | ITag) => {
          if (typeof tag !== "string") {
            return tag;
          }
          return { title: tag, slug: tag } as ITag;
        });
        this.$emit("input", tagEntities);
      },
    },
  },
})
export default class TagInput extends Vue {
  @Prop({ required: false, default: () => [] }) data!: ITag[];

  @Prop({ required: true, default: "value" }) path!: string;

  @Prop({ required: true }) value!: ITag[];

  filteredTags: ITag[] = [];

  getFilteredTags(text: string): void {
    this.filteredTags = differenceBy(this.data, this.value, "id").filter(
      (option) =>
        get(option, this.path)
          .toString()
          .toLowerCase()
          .indexOf(text.toLowerCase()) >= 0
    );
  }
}
</script>
