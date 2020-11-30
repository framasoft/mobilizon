<template>
  <b-autocomplete
    :data="baseData"
    :placeholder="$t('Actor')"
    v-model="name"
    field="preferredUsername"
    :loading="$apollo.loading"
    check-infinite-scroll
    @typing="getAsyncData"
    @select="handleSelect"
    @infinite-scroll="getAsyncData"
  >
    <template slot-scope="props">
      <div class="media">
        <div class="media-left">
          <img
            width="32"
            :src="props.option.avatar.url"
            v-if="props.option.avatar"
            alt=""
          />
          <b-icon v-else icon="account-circle" />
        </div>
        <div class="media-content">
          <span v-if="props.option.name">
            {{ props.option.name }}
            <br />
            <small>{{ `@${props.option.preferredUsername}` }}</small>
            <small v-if="props.option.domain">{{
              `@${props.option.domain}`
            }}</small>
          </span>
          <span v-else>
            {{ `@${props.option.preferredUsername}` }}
          </span>
        </div>
      </div>
    </template>
    <template slot="footer">
      <span class="has-text-grey" v-show="page > totalPages">
        Thats it! No more movies found.
      </span>
    </template>
  </b-autocomplete>
</template>
<script lang="ts">
import { Component, Model, Vue, Watch } from "vue-property-decorator";
import { debounce } from "lodash";
import { IPerson } from "@/types/actor";
import { SEARCH_PERSONS } from "@/graphql/search";
import { Paginate } from "@/types/paginate";

const SEARCH_PERSON_LIMIT = 10;

@Component
export default class ActorAutoComplete extends Vue {
  @Model("change", { type: Object }) readonly defaultSelected!: IPerson | null;

  baseData: IPerson[] = [];

  selected: IPerson | null = this.defaultSelected;

  name: string = this.defaultSelected
    ? this.defaultSelected.preferredUsername
    : "";

  page = 1;

  totalPages = 1;

  mounted(): void {
    this.selected = this.defaultSelected;
  }

  data(): Record<string, unknown> {
    return {
      getAsyncData: debounce(this.doGetAsyncData, 500),
    };
  }

  @Watch("defaultSelected")
  updateDefaultSelected(defaultSelected: IPerson): void {
    console.log("update defaultSelected", defaultSelected);
    this.selected = defaultSelected;
    this.name = defaultSelected.preferredUsername;
  }

  handleSelect(selected: IPerson): void {
    this.selected = selected;
    this.$emit("change", selected);
  }

  async doGetAsyncData(name: string): Promise<void> {
    this.baseData = [];
    if (this.name !== name) {
      this.name = name;
      this.page = 1;
    }
    if (!name.length) {
      this.page = 1;
      this.totalPages = 1;
      return;
    }
    const {
      data: { searchPersons },
    } = await this.$apollo.query<{ searchPersons: Paginate<IPerson> }>({
      query: SEARCH_PERSONS,
      variables: {
        searchText: this.name,
        page: this.page,
        limit: SEARCH_PERSON_LIMIT,
      },
    });
    this.totalPages = Math.ceil(searchPersons.total / SEARCH_PERSON_LIMIT);
    this.baseData.push(...searchPersons.elements);
  }
}
</script>
