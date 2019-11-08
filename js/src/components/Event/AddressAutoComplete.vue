<template>
    <div>
        <b-field expanded>
            <template slot="label">
                {{ $t('Find an address') }}
                <b-button v-if="!gettingLocation" size="is-small" icon-right="map-marker" @click="locateMe" />
                <span v-else>{{ $t('Getting location') }}</span>
            </template>
            <b-autocomplete
                    :data="data"
                    v-model="queryText"
                    :placeholder="$t('e.g. 10 Rue Jangot')"
                    field="fullName"
                    :loading="isFetching"
                    @typing="getAsyncData"
                    icon="map-marker"
                    expanded
                    @select="updateSelected">

                <template slot-scope="{option}">
                    <b-icon :icon="option.poiInfos.poiIcon.icon" />
                    <b>{{ option.poiInfos.name }}</b><br />
                    <small>{{ option.poiInfos.alternativeName }}</small>
                </template>
                <template slot="empty">
                    <span v-if="isFetching">{{ $t('Searching…') }}</span>
                    <div v-else class="is-enabled">
                        <span>{{ $t('No results for "{queryText}". You can try another search term or drag and drop the marker on the map', { queryText }) }}</span>
<!--                        <p class="control" @click="openNewAddressModal">-->
<!--                            <button type="button" class="button is-primary">{{ $t('Add') }}</button>-->
<!--                        </p>-->
                    </div>
                </template>
            </b-autocomplete>
        </b-field>
        <div class="map" v-if="selected && selected.geom">
            <map-leaflet
                    :coords="selected.geom"
                    :marker="{ text: [selected.poiInfos.name, selected.poiInfos.alternativeName], icon: selected.poiInfos.poiIcon.icon}"
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
import { Component, Prop, Vue, Watch } from 'vue-property-decorator';
import { Address, IAddress } from '@/types/address.model';
import { ADDRESS, REVERSE_GEOCODE } from '@/graphql/address';
import { Modal } from 'buefy/dist/components/dialog';
import { LatLng } from 'leaflet';

@Component({
  components: {
    'map-leaflet': () => import(/* webpackChunkName: "map" */ '@/components/Map.vue'),
    Modal,
  },
})
export default class AddressAutoComplete extends Vue {

  @Prop({ required: true }) value!: IAddress;

  data: IAddress[] = [];
  selected!: IAddress;
  isFetching: boolean = false;
  queryText: string = this.value && (new Address(this.value)).fullName || '';
  addressModalActive: boolean = false;
  private gettingLocation: boolean = false;
  private location!: Position;
  private gettingLocationError: any;
  private mapDefaultZoom: number = 15;

  @Watch('value')
  updateEditing() {
    this.selected = this.value;
    const address = new Address(this.selected);
    this.queryText = `${address.poiInfos.name} ${address.poiInfos.alternativeName}`;
  }

  async getAsyncData(query) {
    if (!query.length) {
      this.data = [];
      this.selected = new Address();
      return;
    }

    if (query.length < 3) {
      this.data = [];
      return;
    }
    this.isFetching = true;
    const result = await this.$apollo.query({
      query: ADDRESS,
      fetchPolicy: 'network-only',
      variables: {
        query,
        locale: this.$i18n.locale,
      },
    });

    this.data = result.data.searchAddress.map(address => new Address(address));
    this.isFetching = false;
  }

  updateSelected(option) {
    if (option == null) return;
    this.selected = option;
    console.log('update selected', this.selected);
    this.$emit('input', this.selected);
  }

  resetPopup() {
    this.selected = new Address();
  }

  openNewAddressModal() {
    this.resetPopup();
    this.addressModalActive = true;
  }

  async reverseGeoCode(e: LatLng, zoom: Number) {
    // If the position has been updated through autocomplete selection, no need to geocode it !
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

    this.data = result.data.reverseGeocode.map(address => new Address(address));
    const defaultAddress = new Address(this.data[0]);
    this.selected = defaultAddress;
    this.$emit('input', this.selected);
    this.queryText = `${defaultAddress.poiInfos.name} ${defaultAddress.poiInfos.alternativeName}`;
  }

  checkCurrentPosition(e: LatLng) {
    if (!this.selected || !this.selected.geom) return false;
    const lat = parseFloat(this.selected.geom.split(';')[1]);
    const lon = parseFloat(this.selected.geom.split(';')[0]);

    return e.lat === lat && e.lng === lon;
  }

  async locateMe(): Promise<void> {

    this.gettingLocation = true;
    try {
      this.gettingLocation = false;
      this.location = await this.getLocation();
      this.mapDefaultZoom = 12;
      this.reverseGeoCode(new LatLng(this.location.coords.latitude, this.location.coords.longitude), 12);
    } catch (e) {
      this.gettingLocation = false;
      this.gettingLocationError = e.message;
    }
  }

  async getLocation(): Promise<Position> {
    return new Promise((resolve, reject) => {

      if (!('geolocation' in navigator)) {
        reject(new Error('Geolocation is not available.'));
      }

      navigator.geolocation.getCurrentPosition(pos => {
        resolve(pos);
      },                                       err => {
        reject(err);
      });

    });
  }
}
</script>
<style lang="scss">
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
