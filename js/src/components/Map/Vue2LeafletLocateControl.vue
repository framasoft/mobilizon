<template>
  <div style="display: none">
    <slot v-if="ready"></slot>
  </div>
</template>

<script lang="ts">
/**
 * Fork of https://github.com/domoritz/leaflet-locatecontrol
 * to try to trigger location manually (not done ATM)
 */

import L, { DomEvent } from "leaflet";
import { findRealParent, propsBinder } from "vue2-leaflet";
import "leaflet.locatecontrol";
import { Component, Prop, Vue } from "vue-property-decorator";

@Component({
  beforeDestroy() {
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    this.parentContainer.removeLayer(this);
  },
})
export default class Vue2LeafletLocateControl extends Vue {
  @Prop({ type: Object, default: () => ({}) }) options!: Record<
    string,
    unknown
  >;

  @Prop({ type: Boolean, default: true }) visible = true;

  ready = false;

  mapObject!: any;

  parentContainer: any;

  mounted(): void {
    this.mapObject = L.control.locate(this.options);
    DomEvent.on(this.mapObject, this.$listeners as any);
    propsBinder(this, this.mapObject, this.$props);
    this.ready = true;
    this.parentContainer = findRealParent(this.$parent);
    this.mapObject.addTo(this.parentContainer.mapObject, !this.visible);
  }

  public locate(): void {
    this.mapObject.start();
  }
}
</script>

<style>
@import "~leaflet.locatecontrol/dist/L.Control.Locate.css";
</style>
