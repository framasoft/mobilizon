<template>
  <section>
    <h1>
      <translate>Create a new group</translate>
    </h1>
    <div class="columns">
      <form class="column" @submit="createGroup">
        <b-field :label="$gettext('Group name')">
          <b-input aria-required="true" required v-model="group.preferred_username"/>
        </b-field>

        <b-field :label="$gettext('Group full name')">
          <b-input aria-required="true" required v-model="group.name"/>
        </b-field>

        <b-field :label="$gettext('Description')">
          <b-input aria-required="true" required v-model="group.summary" type="textarea"/>
        </b-field>

        <button class="button is-primary">
          <translate>Create my group</translate>
        </button>
      </form>
    </div>
  </section>
</template>

<script lang="ts">
import { Component, Vue } from "vue-property-decorator";

// VueMarkdown is untyped
const VueMarkdown = require('vue-markdown')

@Component({
  components: {
    VueMarkdown
  }
})
export default class CreateGroup extends Vue {
  e1 = 0;
  // FIXME: correctly type group
  group: {
    preferred_username: string;
    name: string;
    summary: string;
    address?: any;
  } = {
    preferred_username: '',
    name: '',
    summary: '',
    // category: null,
  };
  categories = [];

  mounted() {
    this.fetchCategories();
  }

  createGroup() {
    // this.group.organizer = "/accounts/" + this.$store.state.user.id;
    // FIXME: remove eventFetch
    // eventFetch('/groups', this.$store, { method: 'POST', body: JSON.stringify({ group: this.group }) })
    //   .then(response => response.json())
    //   .then((data) => {
    //     this.loading = false;
    //     this.$router.push({ path: 'Group', params: { id: data.id } });
    //   });
  }

  fetchCategories() {
    // FIXME: remove eventFetch
    // eventFetch('/categories', this.$store)
    //   .then(response => response.json())
    //   .then((data) => {
    //     this.loading = false;
    //     this.categories = data.data;
    //   });
  }

  getAddressData(addressData) {
    this.group.address = {
      geo: {
        latitude: addressData.latitude,
        longitude: addressData.longitude
      },
      addressCountry: addressData.country,
      addressLocality: addressData.city,
      addressRegion: addressData.administrative_area_level_1,
      postalCode: addressData.postal_code,
      streetAddress: `${addressData.street_number} ${addressData.route}`
    };
  }
}
</script>

<style>
.markdown-render h1 {
  font-size: 2em;
}
</style>
