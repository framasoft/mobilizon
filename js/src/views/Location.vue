<template>
  <div>{{ center.lat }} - {{ center.lng }}</div>
</template>

<script lang="ts">
import { Component, Prop, Vue } from 'vue-property-decorator';

@Component
export default class Location extends Vue {
  @Prop(String) address!: string;

  description = 'Paris, France';
  center = { lat: 48.85, lng: 2.35 };
  markers: any[] = [];

  setPlace(place) {
    this.center = {
      lat: place.geometry.location.lat(),
      lng: place.geometry.location.lng(),
    };
    this.markers = [
      {
        position: { lat: this.center.lat, lng: this.center.lng },
      },
    ];

    this.$emit('input', place.formatted_address);
  }
}
</script>
