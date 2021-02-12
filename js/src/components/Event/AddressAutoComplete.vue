<template>
  <div class="address-autocomplete">
    <b-field expanded>
      <b-autocomplete
        :data="addressData"
        v-model="queryText"
        :placeholder="$t('e.g. 10 Rue Jangot')"
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
      </b-autocomplete>
    </b-field>
    <b-field v-if="isSecureContext()">
      <b-button
        type="is-text"
        v-if="!gettingLocation"
        icon-right="target"
        @click="locateMe"
        >{{ $t("Use my location") }}</b-button
      >
      <span v-else>{{ $t("Getting location") }}</span>
    </b-field>
    <!--
    <div v-if="selected && selected.geom" class="control">
      <b-checkbox  @input="togglemap" />
      <label class="label">{{ $t("Show map") }}</label>
    </div>

    <div class="map" v-if="showmap && selected && selected.geom">
      <map-leaflet
        :coords="selected.geom"
        :marker="{
          text: [selected.poiInfos.name, selected.poiInfos.alternativeName],
          icon: selected.poiInfos.poiIcon.icon,
        }"
        :updateDraggableMarkerCallback="reverseGeoCode"
        :options="{ zoom: mapDefaultZoom }"
        :readOnly="false"
      />
    </div>
    -->
  </div>
</template>
<script lang="ts">
import { Component, Prop, Vue, Watch } from "vue-property-decorator";
import { LatLng } from "leaflet";
import { debounce, DebouncedFunc } from "lodash";
import { Address, IAddress } from "../../types/address.model";
import { ADDRESS, REVERSE_GEOCODE } from "../../graphql/address";
import { CONFIG } from "../../graphql/config";
import { IConfig } from "../../types/config.model";

@Component({
  components: {
    "map-leaflet": () =>
      import(/* webpackChunkName: "map" */ "@/components/Map.vue"),
  },
  apollo: {
    config: CONFIG,
  },
})
export default class AddressAutoComplete extends Vue {
  @Prop({ required: true }) value!: IAddress;
  @Prop({ required: false, default: false }) type!: string | false;

  addressData: IAddress[] = [];

  selected: IAddress = new Address();

  isFetching = false;

  queryText: string = (this.value && new Address(this.value).fullName) || "";

  addressModalActive = false;

  showmap = false;

  private gettingLocation = false;

  // eslint-disable-next-line no-undef
  private location!: GeolocationPosition;

  private gettingLocationError: any;

  private mapDefaultZoom = 15;

  config!: IConfig;

  fetchAsyncData!: DebouncedFunc<(query: string) => Promise<void>>;

  // We put this in data because of issues like
  // https://github.com/vuejs/vue-class-component/issues/263
  data(): Record<string, unknown> {
    return {
      fetchAsyncData: debounce(this.asyncData, 200),
    };
  }

  async asyncData(query: string): Promise<void> {
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
    const variables: { query: string; locale: string; type?: string } = {
      query,
      locale: this.$i18n.locale,
    };
    if (this.type) {
      variables.type = this.type;
    }
    const result = await this.$apollo.query({
      query: ADDRESS,
      fetchPolicy: "network-only",
      variables,
    });

    this.addressData = result.data.searchAddress.map(
      (address: IAddress) => new Address(address)
    );
    this.isFetching = false;
  }

  @Watch("config")
  watchConfig(config: IConfig): void {
    if (!config.geocoding.autocomplete) {
      // If autocomplete is disabled, we put a larger debounce value
      // so that we don't request with incomplete address
      this.fetchAsyncData = debounce(this.asyncData, 2000);
    }
  }

  @Watch("value")
  updateEditing(): void {
    if (!this.value?.id) return;
    this.selected = this.value;
    const address = new Address(this.selected);
    this.queryText = `${address.poiInfos.name} ${address.poiInfos.alternativeName}`;
  }

  updateSelected(option: IAddress): void {
    if (option == null) return;
    this.selected = option;
    this.$emit("input", this.selected);
  }

  resetPopup(): void {
    this.selected = new Address();
  }

  openNewAddressModal(): void {
    this.resetPopup();
    this.addressModalActive = true;
  }

  togglemap(): void {
    this.showmap = !this.showmap;
  }

  async reverseGeoCode(e: LatLng, zoom: number): Promise<void> {
    // If the position has been updated through autocomplete selection, no need to geocode it!
    if (this.checkCurrentPosition(e)) return;
    const result = await this.$apollo.query({
      query: REVERSE_GEOCODE,
      variables: {
        latitude: e.lat,
        longitude: e.lng,
        zoom,
        locale: this.$i18n.locale,
      },
    });

    this.addressData = result.data.reverseGeocode.map(
      (address: IAddress) => new Address(address)
    );
    if (this.addressData.length > 0) {
      const defaultAddress = new Address(this.addressData[0]);
      this.selected = defaultAddress;
      this.$emit("input", this.selected);
      this.queryText = `${defaultAddress.poiInfos.name} ${defaultAddress.poiInfos.alternativeName}`;
    }
  }

  checkCurrentPosition(e: LatLng): boolean {
    if (!this.selected || !this.selected.geom) return false;
    const lat = parseFloat(this.selected.geom.split(";")[1]);
    const lon = parseFloat(this.selected.geom.split(";")[0]);

    return e.lat === lat && e.lng === lon;
  }

  async locateMe(): Promise<void> {
    this.gettingLocation = true;
    try {
      this.location = await AddressAutoComplete.getLocation();
      this.mapDefaultZoom = 12;
      this.reverseGeoCode(
        new LatLng(
          this.location.coords.latitude,
          this.location.coords.longitude
        ),
        12
      );
    } catch (e) {
      console.error(e);
      this.gettingLocationError = e.message;
    }
    this.gettingLocation = false;
  }

  // eslint-disable-next-line no-undef
  static async getLocation(): Promise<GeolocationPosition> {
    return new Promise((resolve, reject) => {
      if (!("geolocation" in navigator)) {
        reject(new Error("Geolocation is not available."));
      }

      navigator.geolocation.getCurrentPosition(
        (pos) => {
          resolve(pos);
        },
        (err) => {
          reject(err);
        }
      );
    });
  }

  // eslint-disable-next-line class-methods-use-this
  isSecureContext(): boolean {
    return window.isSecureContext;
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
