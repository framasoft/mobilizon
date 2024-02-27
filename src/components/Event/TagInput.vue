<template>
  <o-field :label-for="id" class="taginput-field">
    <template #label>
      <p class="inline-flex items-center gap-0.5">
        {{ t("Add some tags") }}
        <o-tooltip
          variant="dark"
          :label="
            t('You can add tags by hitting the Enter key or by adding a comma')
          "
        >
          <HelpCircleOutline :size="16" />
        </o-tooltip>
      </p>
    </template>
    <o-taginput
      :modelValue="tagsStrings"
      @update:modelValue="updateTags"
      :data="filteredTags"
      :allow-autocomplete="true"
      :allow-new="true"
      :field="'title'"
      icon="label"
      :maxlength="20"
      :maxitems="10"
      :placeholder="t('Eg: Stockholm, Dance, Chess…')"
      @input="getFilteredTags"
      :id="id"
      dir="auto"
      expanded
    >
    </o-taginput>
  </o-field>
</template>
<script lang="ts" setup>
import differenceBy from "lodash/differenceBy";
import { ITag } from "../../types/tag.model";
import { computed, onBeforeMount, ref, watch } from "vue";
import HelpCircleOutline from "vue-material-design-icons/HelpCircleOutline.vue";
import { useFetchTags } from "@/composition/apollo/tags";
import { FILTER_TAGS } from "@/graphql/tags";
import { useI18n } from "vue-i18n";

const props = defineProps<{
  modelValue: ITag[];
}>();

const propsValue = computed(() => props.modelValue);

const tagsStrings = ref<string[]>([]);

const emit = defineEmits(["update:modelValue"]);

const text = ref("");

const tags = ref<ITag[]>([]);

const { t } = useI18n({ useScope: "global" });

let componentId = 0;

onBeforeMount(() => {
  componentId += 1;
});

const id = computed((): string => {
  return `tag-input-${componentId}`;
});

const { load: fetchTags } = useFetchTags();

const getFilteredTags = async (newText: string): Promise<void> => {
  text.value = newText;
  const res = await fetchTags(
    FILTER_TAGS,
    { filter: newText },
    { debounce: 200 }
  );
  if (res) {
    tags.value = res.tags;
  }
};

const filteredTags = computed((): ITag[] => {
  return differenceBy(tags.value, propsValue.value, "id").filter(
    (option) =>
      option.title.toString().toLowerCase().indexOf(text.value.toLowerCase()) >=
        0 ||
      option.slug.toString().toLowerCase().indexOf(text.value.toLowerCase()) >=
        0
  );
});

watch(props.modelValue, (newValue, oldValue) => {
  if (newValue != oldValue) {
    tagsStrings.value = propsValue.value.map((tag: ITag) => tag.title);
  }
});

const updateTags = (newTagsStrings: string[]) => {
  const tagEntities = newTagsStrings.map((tag: string | ITag) => {
    if (typeof tag !== "string") {
      return tag;
    }
    return { title: tag, slug: tag } as ITag;
  });
  emit("update:modelValue", tagEntities);
};
</script>
