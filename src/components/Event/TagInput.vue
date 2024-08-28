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

initTagsStringsValue();

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

const updateTags = (newTagsStrings: string[]) => {
  const tagEntities = newTagsStrings.map((tag: string | ITag) => {
    if (typeof tag !== "string") {
      return tag;
    }
    return { title: tag, slug: tag } as ITag;
  });
  emit("update:modelValue", tagEntities);
};

function isArraysEquals(array1: string[], array2: string[]) {
  if (array1.length !== array2.length) {
    return false;
  }

  for (let i = 0; i < array1.length; i++) {
    if (array1[i] !== array2[i]) {
      return false;
    }
  }

  return true;
}

function initTagsStringsValue() {
  // This is useful when tag data is already cached from the API during navigation inside the app
  tagsStrings.value = propsValue.value.map((tag: ITag) => tag.title);

  // This watch() function is useful when tag data loads directly from the API upon page load
  watch(propsValue, () => {
    const newTagsStrings = propsValue.value.map((tag: ITag) => tag.title);

    // Changing tagsStrings.value triggers updateTags(), updateTags() triggers this watch() function again.
    // To stop the loop, edit tagsStrings.value only if it has changed !
    if (!isArraysEquals(tagsStrings.value, newTagsStrings)) {
      tagsStrings.value = newTagsStrings;
    }
  });
}
</script>
