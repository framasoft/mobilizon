<template>
  <o-field :label-for="id">
    <template #label>
      {{ $t("Add some tags") }}
      <o-tooltip
        variant="dark"
        :label="
          $t('You can add tags by hitting the Enter key or by adding a comma')
        "
      >
        <HelpCircleOutline :size="16" />
      </o-tooltip>
    </template>
    <o-inputitems
      v-model="tagsStrings"
      :data="filteredTags"
      :allow-autocomplete="true"
      :allow-new="true"
      :field="'title'"
      icon="label"
      :maxlength="20"
      :maxitems="10"
      :placeholder="$t('Eg: Stockholm, Dance, Chess…')"
      @typing="debouncedGetFilteredTags"
      :id="id"
      dir="auto"
    >
    </o-inputitems>
  </o-field>
</template>
<script lang="ts" setup>
import differenceBy from "lodash/differenceBy";
import { ITag } from "../../types/tag.model";
import debounce from "lodash/debounce";
import { computed, onBeforeMount, ref } from "vue";
import HelpCircleOutline from "vue-material-design-icons/HelpCircleOutline.vue";

const props = defineProps<{
  modelValue: ITag[];
  fetchTags: (text: string) => Promise<ITag[]>;
}>();

const emit = defineEmits(["update:modelValue"]);

const text = ref("");

const tags = ref<ITag[]>([]);

let componentId = 0;

onBeforeMount(() => {
  componentId += 1;
});

const id = computed((): string => {
  return `tag-input-${componentId}`;
});

const getFilteredTags = async (newText: string): Promise<void> => {
  text.value = newText;
  tags.value = await props.fetchTags(newText);
};

const debouncedGetFilteredTags = debounce(getFilteredTags, 200);

const filteredTags = computed((): ITag[] => {
  return differenceBy(tags.value, props.modelValue, "id").filter(
    (option) =>
      option.title.toString().toLowerCase().indexOf(text.value.toLowerCase()) >=
        0 ||
      option.slug.toString().toLowerCase().indexOf(text.value.toLowerCase()) >=
        0
  );
});

const tagsStrings = computed({
  get(): string[] {
    return props.modelValue.map((tag: ITag) => tag.title);
  },
  set(newTagsStrings: string[]) {
    console.debug("tagsStrings", newTagsStrings);
    const tagEntities = newTagsStrings.map((tag: string | ITag) => {
      if (typeof tag !== "string") {
        return tag;
      }
      return { title: tag, slug: tag } as ITag;
    });
    emit("update:modelValue", tagEntities);
  },
});
</script>
