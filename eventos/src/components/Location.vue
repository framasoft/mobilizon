<template>
  <div>

    <!--<gmap-autocomplete :value="description" @input="setPlace"
                       @place_changed="setPlace">
    </gmap-autocomplete>
    <br />

    <gmap-map
      :center="center"
      :zoom="15"
      style="width: 500px; height: 300px"
    >
      <gmap-marker
        :key="index"
        v-for="(m, index) in markers"
        :position="m.position"
        :clickable="true"
        :draggable="true"
        @click="center=m.position"
      ></gmap-marker>
    </gmap-map>-->
    {{ center.lat }} - {{ center.lng }}
  </div>
</template>

<script>

  export default {
    data() {
      return {
        description: 'Paris, France',
        center: { lat: 48.85, lng: 2.35 },
        markers: [],
      };
    },
    props: ['address'],
    methods: {
      setPlace(place) {
        this.center = {
          lat: place.geometry.location.lat(),
          lng: place.geometry.location.lng(),
        };
        this.markers = [{
          position: { lat: this.center.lat, lng: this.center.lng },
        }];
        this.$emit('input', place.formatted_address);
      },
    },
  };

</script>
