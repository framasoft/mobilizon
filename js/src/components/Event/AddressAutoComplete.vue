<template>
  <b-autocomplete
    :data="addressData"
    v-model="queryText"
    :placeholder="placeholder || $t('e.g. 10 Rue Jangot')"
    field="fullName"
    :loading="isFetching"
    @typing="fetchAsyncData"
    icon="map-marker"
    expanded
    @select="updateSelected"
  >
    <template slot-scope="{ option }">
      <b-icon :icon="option.poiInfos.poiIcon.icon" />
      <b>{{ option.poiInfos.name }}</b
      ><br />
      <small>{{ option.poiInfos.alternativeName }}</small>
    </template>
    <template slot="empty">
      <span v-if="isFetching">{{ $t("Searching…") }}</span>
      <div v-else-if="queryText.length >= 3" class="is-enabled">
        <span>{{ $t('No results for "{queryText}"') }}</span>
        <span>{{
          $t("You can try another search term or drag and drop the marker on the map", {
            queryText,
          })
        }}</span>
      </div>
    </template>
  </b-autocomplete>
</template>
<script lang="ts">
import { Component, Prop, Vue, Watch } from "vue-property-decorator";
import { LatLng } from "leaflet";
import { debounce } from "lodash";
import { Address, IAddress } from "../../types/address.model";
import { ADDRESS, REVERSE_GEOCODE } from "../../graphql/address";
import { CONFIG } from "../../graphql/config";
import { IConfig } from "../../types/config.model";

@Component({
  apollo: {
    config: CONFIG,
  },
})
export default class AddressAutoComplete extends Vue {
  @Prop({ required: true }) value!: IAddress;
  @Prop({ required: false }) placeholder!: string;

  addressData: IAddress[] = [];

  selected: IAddress = new Address();

  isFetching = false;

  queryText: string = (this.value && new Address(this.value).fullName) || "";

  config!: IConfig;

  fetchAsyncData!: Function;

  // We put this in data because of issues like
  // https://github.com/vuejs/vue-class-component/issues/263
  data() {
    return {
      fetchAsyncData: debounce(this.asyncData, 200),
    };
  }

  async asyncData(query: string) {
    if (!query.length) {
      this.addressData = [];
      this.selected = new Address();
      return;
    }

    if (query.length < 3) {
      this.addressData = [];
      return;
    }

    this.isFetching = true;
    const result = await this.$apollo.query({
      query: ADDRESS,
      fetchPolicy: "network-only",
      variables: {
        query,
        locale: this.$i18n.locale,
      },
    });

    this.addressData = result.data.searchAddress.map((address: IAddress) => new Address(address));
    this.isFetching = false;
  }

  @Watch("config")
  watchConfig(config: IConfig) {
    if (!config.geocoding.autocomplete) {
      // If autocomplete is disabled, we put a larger debounce value
      // so that we don't request with incomplete address
      this.fetchAsyncData = debounce(this.asyncData, 2000);
    }
  }

  @Watch("value")
  updateEditing() {
    if (!(this.value && this.value.id)) return;
    this.selected = this.value;
    const address = new Address(this.selected);
    this.queryText = `${address.poiInfos.name} ${address.poiInfos.alternativeName}`;
  }

  updateSelected(option: IAddress) {
    if (option == null) return;
    this.selected = option;
    this.$emit("input", this.selected);
  }
}
</script>
<style lang="scss">
.address-autocomplete {
  margin-bottom: 0.75rem;
}

.autocomplete {
  .dropdown-menu {
    z-index: 2000;
  }

  .dropdown-item.is-disabled {
    opacity: 1 !important;
    cursor: auto;
  }
}

.read-only {
  cursor: pointer;
}

.map {
  height: 400px;
  width: 100%;
}
</style>
