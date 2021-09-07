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
        v-bind="$attrs"
      >
        <template #default="{ option }">
          <b-icon :icon="option.poiInfos.poiIcon.icon" />
          <b>{{ option.poiInfos.name }}</b
          ><br />
          <small>{{ option.poiInfos.alternativeName }}</small>
        </template>
      </b-autocomplete>
    </b-field>
    <b-field
      v-if="canDoGeoLocation"
      :message="fieldErrors"
      :type="{ 'is-danger': fieldErrors.length }"
    >
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
import { Component, Mixins, Prop, Watch } from "vue-property-decorator";
import { Address, IAddress } from "../../types/address.model";
import AddressAutoCompleteMixin from "@/mixins/AddressAutoCompleteMixin";

@Component({
  inheritAttrs: false,
})
export default class AddressAutoComplete extends Mixins(
  AddressAutoCompleteMixin
) {
  @Prop({ required: false, default: false }) type!: string | false;
  @Prop({ required: false, default: true, type: Boolean })
  doGeoLocation!: boolean;

  addressData: IAddress[] = [];

  selected: IAddress = new Address();

  initialQueryText = "";

  addressModalActive = false;

  showmap = false;

  get queryText2(): string {
    if (this.value !== undefined) {
      return new Address(this.value).fullName;
    }
    return this.initialQueryText;
  }

  set queryText2(queryText: string) {
    this.initialQueryText = queryText;
  }

  @Watch("value")
  updateEditing(): void {
    if (!this.value?.id) return;
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

  togglemap(): void {
    this.showmap = !this.showmap;
  }

  get canDoGeoLocation(): boolean {
    return this.isSecureContext && this.doGeoLocation;
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
