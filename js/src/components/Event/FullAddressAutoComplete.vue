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
          <span
            class="is-size-6 has-text-weight-normal"
            v-if="gettingLocation"
            >{{ $t("Getting location") }}</span
          >
        </template>
        <p class="control" v-if="canShowLocateMeButton && !gettingLocation">
          <b-button
            icon-right="map-marker"
            @click="locateMe"
            :title="$t('Use my location')"
          />
        </p>
        <b-autocomplete
          :data="addressData"
          v-model="queryText"
          :placeholder="$t('e.g. 10 Rue Jangot')"
          field="fullName"
          :loading="isFetching"
          @typing="fetchAsyncData"
          :icon="canShowLocateMeButton ? null : 'map-marker'"
          expanded
          @select="updateSelected"
          v-bind="$attrs"
          :id="id"
          :disabled="disabled"
          dir="auto"
        >
          <template #default="{ option }">
            <b-icon :icon="option.poiInfos.poiIcon.icon" />
            <b>{{ option.poiInfos.name }}</b
            ><br />
            <small>{{ option.poiInfos.alternativeName }}</small>
          </template>
          <template #empty>
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
      <div
        class="card"
        v-if="!hideSelected && (selected.originId || selected.url)"
      >
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
      v-if="!hideMap && selected && selected.geom && selected.poiInfos"
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
  @Prop({ required: false, default: false, type: Boolean }) disabled!: boolean;
  @Prop({ required: false, default: false, type: Boolean }) hideMap!: boolean;
  @Prop({ required: false, default: false, type: Boolean })
  hideSelected!: boolean;

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
