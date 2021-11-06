import { Component, Prop, Vue, Watch } from "vue-property-decorator";
import { LatLng } from "leaflet";
import { Address, IAddress } from "../types/address.model";
import { ADDRESS, REVERSE_GEOCODE } from "../graphql/address";
import { CONFIG } from "../graphql/config";
import { IConfig } from "../types/config.model";
import debounce from "lodash/debounce";
import { DebouncedFunc } from "lodash";
import { PropType } from "vue";

@Component({
  components: {
    "map-leaflet": () =>
      import(/* webpackChunkName: "map" */ "@/components/Map.vue"),
  },
  apollo: {
    config: CONFIG,
  },
})
export default class AddressAutoCompleteMixin extends Vue {
  @Prop({ required: true, type: Object as PropType<IAddress> })
  value!: IAddress;
  gettingLocationError: string | null = null;

  gettingLocation = false;

  mapDefaultZoom = 15;

  addressData: IAddress[] = [];

  selected: IAddress = new Address();

  config!: IConfig;

  isFetching = false;

  fetchAsyncData!: DebouncedFunc<(query: string) => Promise<void>>;

  // eslint-disable-next-line no-undef
  protected location!: GeolocationPosition;

  // We put this in data because of issues like
  // https://github.com/vuejs/vue-class-component/issues/263
  data(): Record<string, unknown> {
    return {
      fetchAsyncData: debounce(this.asyncData, 200),
    };
  }

  @Watch("config")
  watchConfig(config: IConfig): void {
    if (!config.geocoding.autocomplete) {
      // If autocomplete is disabled, we put a larger debounce value
      // so that we don't request with incomplete address
      this.fetchAsyncData = debounce(this.asyncData, 2000);
    }
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

  get queryText(): string {
    return (this.value && new Address(this.value).fullName) || "";
  }

  set queryText(text: string) {
    if (text === "" && this.selected?.id) {
      console.log("doing reset");
      this.resetAddress();
    }
  }

  resetAddress(): void {
    this.$emit("input", null);
    this.selected = new Address();
  }

  async locateMe(): Promise<void> {
    this.gettingLocation = true;
    this.gettingLocationError = null;
    try {
      this.location = await this.getLocation();
      this.mapDefaultZoom = 12;
      this.reverseGeoCode(
        new LatLng(
          this.location.coords.latitude,
          this.location.coords.longitude
        ),
        12
      );
    } catch (e: any) {
      this.gettingLocationError = e.message;
    }
    this.gettingLocation = false;
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
    }
  }

  checkCurrentPosition(e: LatLng): boolean {
    if (!this.selected || !this.selected.geom) return false;
    const lat = parseFloat(this.selected.geom.split(";")[1]);
    const lon = parseFloat(this.selected.geom.split(";")[0]);

    return e.lat === lat && e.lng === lon;
  }

  // eslint-disable-next-line no-undef
  async getLocation(): Promise<GeolocationPosition> {
    let errorMessage = this.$t("Failed to get location.");
    return new Promise((resolve, reject) => {
      if (!("geolocation" in navigator)) {
        reject(new Error(errorMessage as string));
      }

      navigator.geolocation.getCurrentPosition(
        (pos) => {
          resolve(pos);
        },
        (err) => {
          switch (err.code) {
            // eslint-disable-next-line no-undef
            case GeolocationPositionError.PERMISSION_DENIED:
              errorMessage = this.$t("The geolocation prompt was denied.");
              break;
            // eslint-disable-next-line no-undef
            case GeolocationPositionError.POSITION_UNAVAILABLE:
              errorMessage = this.$t("Your position was not available.");
              break;
            // eslint-disable-next-line no-undef
            case GeolocationPositionError.TIMEOUT:
              errorMessage = this.$t("Geolocation was not determined in time.");
              break;
            default:
              errorMessage = err.message;
          }
          reject(new Error(errorMessage as string));
        }
      );
    });
  }

  get fieldErrors(): Array<Record<string, boolean>> {
    const errors = [];
    if (this.gettingLocationError) {
      errors.push({
        [this.gettingLocationError]: true,
      });
    }
    return errors;
  }

  // eslint-disable-next-line class-methods-use-this
  get isSecureContext(): boolean {
    return window.isSecureContext;
  }
}
