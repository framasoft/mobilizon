<template>
  <section>
    <div class="mb-4">
      <div v-for="(item, index) in metadata" :key="item.key" class="my-2">
        <event-metadata-item
          :value="metadata[index]"
          @input="updateSingleMetadata"
          @removeItem="removeItem"
        />
      </div>
    </div>
    <b-field grouped :label="$t('Find or add an element')">
      <b-autocomplete
        expanded
        v-model="search"
        ref="autocomplete"
        :data="filteredDataArray"
        group-field="category"
        group-options="items"
        open-on-focus
        :placeholder="$t('e.g. Accessibility, Twitch, PeerTube')"
        @select="(option) => addElement(option)"
      >
        <template slot-scope="props">
          <div class="media">
            <div class="media-left">
              <img
                v-if="
                  props.option.icon &&
                  props.option.icon.substring(0, 7) === 'mz:icon'
                "
                :src="`/img/${props.option.icon.substring(8)}_monochrome.svg`"
                width="24"
                height="24"
              />
              <b-icon v-else-if="props.option.icon" :icon="props.option.icon" />
              <b-icon v-else icon="help-circle" />
            </div>
            <div class="media-content">
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
      </b-autocomplete>
      <p class="control">
        <b-button @click="showNewElementModal = true">
          {{ $t("Add new…") }}
        </b-button>
      </p>
    </b-field>
    <b-modal has-modal-card v-model="showNewElementModal">
      <div class="modal-card">
        <header class="modal-card-head">
          <button
            type="button"
            class="delete"
            @click="showNewElementModal = false"
          />
        </header>
        <div class="modal-card-body">
          <form @submit="addNewElement">
            <b-field :label="$t('Element title')">
              <b-input v-model="newElement.title" />
            </b-field>
            <b-field :label="$t('Element value')">
              <b-input v-model="newElement.value" />
            </b-field>
            <b-button type="is-primary" native-type="submit">{{
              $t("Add")
            }}</b-button>
          </form>
        </div>
      </div>
    </b-modal>
  </section>
</template>
<script lang="ts">
import {
  IEventMetadata,
  IEventMetadataDescription,
} from "@/types/event-metadata";
import cloneDeep from "lodash/cloneDeep";
import { PropType } from "vue";
import { Component, Prop, Vue } from "vue-property-decorator";
import EventMetadataItem from "./EventMetadataItem.vue";
import { eventMetaDataList } from "../../services/EventMetadata";
import { EventMetadataCategories, EventMetadataType } from "@/types/enums";

type GroupedIEventMetadata = Array<{
  category: string;
  items: IEventMetadata[];
}>;

@Component({
  components: {
    EventMetadataItem,
  },
})
export default class EventMetadataList extends Vue {
  @Prop({ type: Array as PropType<Array<IEventMetadata>>, required: true })
  value!: IEventMetadata[];

  newElement = {
    title: "",
    value: "",
  };

  search = "";

  data: IEventMetadataDescription[] = eventMetaDataList;

  showNewElementModal = false;

  get metadata(): IEventMetadata[] {
    return this.value.map((val) => {
      const def = this.data.find((dat) => dat.key === val.key);
      return {
        ...def,
        ...val,
      };
    }) as any[];
  }

  set metadata(metadata: IEventMetadata[]) {
    this.$emit("input", metadata);
  }

  localizedCategories: Record<EventMetadataCategories, string> = {
    [EventMetadataCategories.ACCESSIBILITY]: this.$t("Accessibility") as string,
    [EventMetadataCategories.LIVE]: this.$t("Live") as string,
    [EventMetadataCategories.REPLAY]: this.$t("Replay") as string,
    [EventMetadataCategories.TOOLS]: this.$t("Tools") as string,
    [EventMetadataCategories.SOCIAL]: this.$t("Social") as string,
    [EventMetadataCategories.DETAILS]: this.$t("Details") as string,
    [EventMetadataCategories.BOOKING]: this.$t("Booking") as string,
  };

  get filteredDataArray(): GroupedIEventMetadata {
    return this.data
      .filter((option) => {
        return (
          option.label
            .toString()
            .toLowerCase()
            .indexOf(this.search.toLowerCase()) >= 0
        );
      })
      .filter(({ key }) => {
        return !this.metadata.map(({ key: key2 }) => key2).includes(key);
      })
      .reduce(
        (acc: GroupedIEventMetadata, current: IEventMetadataDescription) => {
          const group = acc.find(
            (elem) =>
              elem.category === this.localizedCategories[current.category]
          );
          if (group) {
            group.items.push(current);
          } else {
            acc.push({
              category: this.localizedCategories[current.category],
              items: [current],
            });
          }
          return acc;
        },
        []
      );
  }

  updateSingleMetadata(element: IEventMetadataDescription): void {
    const metadataClone = cloneDeep(this.metadata);
    const index = metadataClone.findIndex((elem) => elem.key === element.key);
    metadataClone.splice(index, 1, element);
    this.$emit("input", metadataClone);
  }

  removeItem(itemKey: string): void {
    const metadataClone = cloneDeep(this.metadata);
    const index = metadataClone.findIndex((elem) => elem.key === itemKey);
    metadataClone.splice(index, 1);
    this.$emit("input", metadataClone);
  }

  addElement(element: IEventMetadata): void {
    this.metadata = [...this.metadata, element];
  }

  addNewElement(e: Event): void {
    e.preventDefault();
    this.addElement({
      ...this.newElement,
      type: EventMetadataType.STRING,
      key: `mz:plain:${(Math.random() + 1).toString(36).substring(7)}`,
    });
    this.showNewElementModal = false;
  }
}
</script>
