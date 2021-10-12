<template>
  <div class="address-autocomplete columns is-desktop">
    <div class="column">
      <b-field
        :label-for="id"
        expanded
        :message="fieldErrors"
        :type="{ 'is-danger': fieldErrors.length }"
      >
        <template slot="label">
          {{ actualLabel }}
          <b-button
            v-if="canShowLocateMeButton && !gettingLocation"
            size="is-small"
            icon-right="map-marker"
            @click="locateMe"
            :title="$t('Use my location')"
          />
          <span
            class="is-size-6 has-text-weight-normal"
            v-else-if="gettingLocation"
            >{{ $t("Getting location") }}</span
          >
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
          v-bind="$attrs"
          :id="id"
        >
          <template #default="{ option }">
            <b-icon :icon="option.poiInfos.poiIcon.icon" />
            <b>{{ option.poiInfos.name }}</b
            ><br />
            <small>{{ option.poiInfos.alternativeName }}</small>
          </template>
          <template slot="empty">
            <span v-if="isFetching">{{ $t("Searching…") }}</span>
            <div v-else-if="queryText.length >= 3" class="is-enabled">
              <span>{{
                $t('No results for "{queryText}"', { queryText })
              }}</span>
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
        <b-button
          :disabled="!queryText"
          @click="resetAddress"
          class="reset-area"
          icon-left="close"
          :title="$t('Clear address field')"
        />
      </b-field>
      <div class="card" v-if="selected.originId || selected.url">
        <div class="card-content">
          <address-info
            :address="selected"
            :show-icon="true"
            :show-timezone="true"
            :user-timezone="userTimezone"
          />
        </div>
      </div>
    </div>
    <div
      class="map column"
      v-if="selected && selected.geom && selected.poiInfos"
    >
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
import { Component, Prop, Watch, Mixins } from "vue-property-decorator";
import { LatLng } from "leaflet";
import { Address, IAddress } from "../../types/address.model";
import AddressAutoCompleteMixin from "../../mixins/AddressAutoCompleteMixin";
import AddressInfo from "../../components/Address/AddressInfo.vue";

@Component({
  inheritAttrs: false,
  components: {
    AddressInfo,
  },
})
export default class FullAddressAutoComplete extends Mixins(
  AddressAutoCompleteMixin
) {
  @Prop({ required: false, default: "" }) label!: string;
  @Prop({ required: false }) userTimezone!: string;

  addressModalActive = false;

  private static componentId = 0;

  created(): void {
    FullAddressAutoComplete.componentId += 1;
  }

  get id(): string {
    return `full-address-autocomplete-${FullAddressAutoComplete.componentId}`;
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

  checkCurrentPosition(e: LatLng): boolean {
    if (!this.selected || !this.selected.geom) return false;
    const lat = parseFloat(this.selected.geom.split(";")[1]);
    const lon = parseFloat(this.selected.geom.split(";")[0]);

    return e.lat === lat && e.lng === lon;
  }

  get actualLabel(): string {
    return this.label || (this.$t("Find an address") as string);
  }

  // eslint-disable-next-line class-methods-use-this
  get canShowLocateMeButton(): boolean {
    return window.isSecureContext;
  }

  @Watch("queryText")
  resetAddressOnEmptyField(queryText: string): void {
    if (queryText === "" && this.selected?.id) {
      console.log("doing reset");
      this.resetAddress();
    }
  }

  resetAddress(): void {
    this.$emit("input", null);
    this.queryText = "";
    this.selected = new Address();
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
