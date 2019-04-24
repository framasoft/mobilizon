<template>
    <div class="map-container">
        <l-map
                :zoom="mergedOptions.zoom"
                :style="`height: ${mergedOptions.height}; width: ${mergedOptions.width}`"
                class="leaflet-map"
                :center="[lat, lon]"
        >
            <l-tile-layer url="https://{s}.tile.osm.org/{z}/{x}/{y}.png"></l-tile-layer>
            <l-marker :lat-lng="[lat, lon]" >
                <l-popup v-if="popup">{{ popup }}</l-popup>
            </l-marker>
        </l-map>
    </div>
</template>

<script lang="ts">
import { Icon }  from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { Component, Prop, Vue } from 'vue-property-decorator';
import { LMap, LTileLayer, LMarker, LPopup } from 'vue2-leaflet';

@Component({
  components: { LTileLayer, LMap, LMarker, LPopup },
})
export default class Map extends Vue {
  @Prop({ type: String, required: true }) coords!: string;
  @Prop({ type: String, required: false }) popup!: string;
  @Prop({ type: Object, required: false }) options!: object;

  defaultOptions: object = {
    zoom: 15,
    height: '100%',
    width: '100%',
  };

  mounted() {
    // this part resolve an issue where the markers would not appear
    // @ts-ignore
    delete Icon.Default.prototype._getIconUrl;

    Icon.Default.mergeOptions({
      iconRetinaUrl: require('leaflet/dist/images/marker-icon-2x.png'),
      iconUrl: require('leaflet/dist/images/marker-icon.png'),
      shadowUrl: require('leaflet/dist/images/marker-shadow.png'),
    });
  }

  get mergedOptions(): object {
    return { ...this.defaultOptions, ...this.options };
  }

  get lat() { return this.$props.coords.split(';')[0]; }
  get lon() { return this.$props.coords.split(';')[1]; }
}
</script>
<style lang="scss" scoped>
    div.map-container {
        height: 100%;
        width: 100%;

        .leaflet-map {
            z-index: 20;
        }
    }
</style>
