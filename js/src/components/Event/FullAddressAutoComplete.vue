<template>
  <div class="address-autocomplete">
    <b-field expanded>
      <template slot="label">
        {{ actualLabel }}
        <b-button
          v-if="canShowLocateMeButton && !gettingLocation"
          size="is-small"
          icon-right="map-marker"
          @click="locateMe"
        />
        <span v-else-if="gettingLocation">{{ $t("Getting location") }}</span>
      </template>
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
        <template slot="empty">
          <span v-if="isFetching">{{ $t("Searching…") }}</span>
          <div v-else-if="queryText.length >= 3" class="is-enabled">
            <span>{{ $t('No results for "{queryText}"') }}</span>
            <span>{{
              $t(
                "You can try another search term or drag and drop the marker on the map",
                {
                  queryText,
                }
              )
            }}</span>
            <!--                        <p class="control" @click="openNewAddressModal">-->
            <!--                            <button type="button" class="button is-primary">{{ $t('Add') }}</button>-->
            <!--                        </p>-->
          </div>
        </template>
      </b-autocomplete>
    </b-field>
    <div class="map" v-if="selected && selected.geom && selected.poiInfos">
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
    <!--        <b-modal v-if="selected" :active.sync="addressModalActive" :width="640" has-modal-card scroll="keep">-->
    <!--            <div class="modal-card" style="width: auto">-->
    <!--                <header class="modal-card-head">-->
    <!--                    <p class="modal-card-title">{{ $t('Add an address') }}</p>-->
    <!--                </header>-->
    <!--                <section class="modal-card-body">-->
    <!--                    <form>-->
    <!--                        <b-field :label="$t('Name')">-->
    <!--                            <b-input aria-required="true" required v-model="selected.description" />-->
    <!--                        </b-field>-->

    <!--                        <b-field :label="$t('Street')">-->
    <!--                            <b-input v-model="selected.street" />-->
    <!--                        </b-field>-->

    <!--                        <b-field grouped>-->
    <!--                            <b-field :label="$t('Postal Code')">-->
    <!--                                <b-input v-model="selected.postalCode" />-->
    <!--                            </b-field>-->

    <!--                            <b-field :label="$t('Locality')">-->
    <!--                                <b-input v-model="selected.locality" />-->
    <!--                            </b-field>-->
    <!--                        </b-field>-->

    <!--                        <b-field grouped>-->
    <!--                            <b-field :label="$t('Region')">-->
    <!--                                <b-input v-model="selected.region" />-->
    <!--                            </b-field>-->

    <!--                            <b-field :label="$t('Country')">-->
    <!--                                <b-input v-model="selected.country" />-->
    <!--                            </b-field>-->
    <!--                        </b-field>-->
    <!--                    </form>-->
    <!--                </section>-->
    <!--                <footer class="modal-card-foot">-->
    <!--                    <button class="button" type="button" @click="resetPopup()">{{ $t('Clear') }}</button>-->
    <!--                </footer>-->
    <!--            </div>-->
    <!--        </b-modal>-->
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
export default class FullAddressAutoComplete extends Vue {
  @Prop({ required: true }) value!: IAddress;

  @Prop({ required: false, default: "" }) label!: string;

  addressData: IAddress[] = [];

  selected: IAddress = new Address();

  isFetching = false;

  queryText: string = (this.value && new Address(this.value).fullName) || "";

  addressModalActive = false;

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
    const result = await this.$apollo.query({
      query: ADDRESS,
      fetchPolicy: "network-only",
      variables: {
        query,
        locale: this.$i18n.locale,
      },
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
    if (!(this.value && this.value.id)) return;
    this.selected = this.value;
    const address = new Address(this.selected);
    if (address.poiInfos) {
      this.queryText = `${address.poiInfos.name} ${address.poiInfos.alternativeName}`;
    }
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
      this.gettingLocation = false;
      this.location = await FullAddressAutoComplete.getLocation();
      this.mapDefaultZoom = 12;
      this.reverseGeoCode(
        new LatLng(
          this.location.coords.latitude,
          this.location.coords.longitude
        ),
        12
      );
    } catch (e) {
      this.gettingLocation = false;
      this.gettingLocationError = e.message;
    }
  }

  get actualLabel(): string {
    return this.label || (this.$t("Find an address") as string);
  }

  // eslint-disable-next-line class-methods-use-this
  get canShowLocateMeButton(): boolean {
    return window.isSecureContext;
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
