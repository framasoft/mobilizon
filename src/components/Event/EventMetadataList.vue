<template>
  <section>
    <div class="mb-4">
      <div v-for="(item, index) in metadata" :key="item.key" class="my-2">
        <event-metadata-item
          :modelValue="metadata[index]"
          @update:modelValue="updateSingleMetadata"
          @removeItem="removeItem"
        />
      </div>
    </div>
    <o-field
      :label="$t('Find or add an element')"
      label-for="event-metadata-autocomplete"
      class="flex-wrap justify-center gap-2"
    >
      <o-autocomplete
        expanded
        :clear-on-select="true"
        v-model="search"
        ref="autocomplete"
        :data="filteredDataArray"
        group-field="category"
        group-options="items"
        open-on-focus
        :placeholder="$t('e.g. Accessibility, Twitch, PeerTube')"
        id="event-metadata-autocomplete"
        @select="addElement"
        dir="auto"
        class="flex-1 min-w-[200px]"
      >
        <template v-slot="props">
          <div
            class="dark:bg-violet-3 p-1 flex items-center gap-1 flex-1 dark:text-white"
          >
            <div class="">
              <img
                v-if="
                  props.option.icon &&
                  props.option.icon.substring(0, 7) === 'mz:icon'
                "
                :src="`/img/${props.option.icon.substring(8)}_monochrome.svg`"
                width="24"
                height="24"
                alt=""
                class="dark:fill-white"
              />
              <o-icon v-else-if="props.option.icon" :icon="props.option.icon" />
              <o-icon v-else icon="help-circle" />
            </div>
            <div class="">
              <b>{{ props.option.label }}</b>
              <br />
              <small>
                {{ props.option.description }}
              </small>
            </div>
          </div>
        </template>
        <template #empty>{{
          $t("No results for {search}", { search })
        }}</template>
      </o-autocomplete>
      <p class="control">
        <o-button @click="showNewElementModal = true">
          {{ $t("Add new…") }}
        </o-button>
      </p>
    </o-field>
    <o-modal
      has-modal-card
      v-model:active="showNewElementModal"
      :close-button-aria-label="$t('Close')"
    >
      <div class="">
        <header class="">
          <h2>{{ t("Create a new metadata element") }}</h2>
          <p>
            {{
              t(
                "You can put any arbitrary content in this element. URLs will be clickable."
              )
            }}
          </p>
        </header>
        <div class="">
          <form @submit="addNewElement">
            <o-field :label="$t('Element title')">
              <o-input v-model="newElement.title" />
            </o-field>
            <o-field :label="$t('Element value')">
              <o-input v-model="newElement.value" />
            </o-field>
            <o-button class="mt-2" variant="primary" native-type="submit">{{
              $t("Add")
            }}</o-button>
          </form>
        </div>
      </div>
    </o-modal>
  </section>
</template>
<script lang="ts" setup>
import { IEventMetadataDescription } from "@/types/event-metadata";
import cloneDeep from "lodash/cloneDeep";
import { computed, reactive, ref } from "vue";
import EventMetadataItem from "./EventMetadataItem.vue";
import { eventMetaDataList } from "../../services/EventMetadata";
import { EventMetadataCategories, EventMetadataType } from "@/types/enums";
import { useI18n } from "vue-i18n";

type GroupedIEventMetadata = Array<{
  category: string;
  items: IEventMetadataDescription[];
}>;

const props = defineProps<{
  modelValue: IEventMetadataDescription[];
}>();

const emit = defineEmits(["update:modelValue"]);

const newElement = reactive({
  title: "",
  value: "",
});

const { t } = useI18n({ useScope: "global" });

const search = ref("");

const data: IEventMetadataDescription[] = eventMetaDataList;

const showNewElementModal = ref(false);

const metadata = computed({
  get(): IEventMetadataDescription[] {
    return props.modelValue.map((val) => {
      const def = data.find((dat) => dat.key === val.key);
      return {
        ...def,
        ...val,
      };
    }) as any[];
  },
  set(newMetadata: IEventMetadataDescription[]) {
    emit(
      "update:modelValue",
      newMetadata.filter((elem) => elem)
    );
  },
});

const localizedCategories: Record<EventMetadataCategories, string> = {
  [EventMetadataCategories.ACCESSIBILITY]: t("Accessibility") as string,
  [EventMetadataCategories.LIVE]: t("Live") as string,
  [EventMetadataCategories.REPLAY]: t("Replay") as string,
  [EventMetadataCategories.TOOLS]: t("Tools") as string,
  [EventMetadataCategories.SOCIAL]: t("Social") as string,
  [EventMetadataCategories.DETAILS]: t("Details") as string,
  [EventMetadataCategories.BOOKING]: t("Booking") as string,
  [EventMetadataCategories.VIDEO_CONFERENCE]: t("Video Conference") as string,
};

const filteredDataArray = computed((): GroupedIEventMetadata => {
  return data
    .filter((option) => {
      return (
        option.label
          .toString()
          .toLowerCase()
          .indexOf(search.value.toLowerCase()) >= 0
      );
    })
    .filter(({ key }) => {
      return !metadata.value.map(({ key: key2 }) => key2).includes(key);
    })
    .reduce(
      (acc: GroupedIEventMetadata, current: IEventMetadataDescription) => {
        const group = acc.find(
          (elem) => elem.category === localizedCategories[current.category]
        );
        if (group) {
          group.items.push(current);
        } else {
          acc.push({
            category: localizedCategories[current.category],
            items: [current],
          });
        }
        return acc;
      },
      []
    );
});

const updateSingleMetadata = (element: IEventMetadataDescription): void => {
  const metadataClone = cloneDeep(metadata.value);
  const index = metadataClone.findIndex((elem) => elem.key === element.key);
  metadataClone.splice(index, 1, element);
  emit("update:modelValue", metadataClone);
};

const removeItem = (itemKey: string): void => {
  const metadataClone = cloneDeep(metadata.value);
  const index = metadataClone.findIndex((elem) => elem.key === itemKey);
  metadataClone.splice(index, 1);
  emit("update:modelValue", metadataClone);
};

const addElement = (element: IEventMetadataDescription): void => {
  metadata.value = [...metadata.value, element];
};

const addNewElement = (e: Event): void => {
  e.preventDefault();
  addElement({
    ...newElement,
    type: EventMetadataType.STRING,
    key: `mz:plain:${(Math.random() + 1).toString(36).substring(7)}`,
    category: EventMetadataCategories.DETAILS,
    label: "",
  });
  showNewElementModal.value = false;
};
</script>
