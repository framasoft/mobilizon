<template>
  <section class="container has-text-centered not-found">
    <div class="columns is-vertical">
      <div class="column is-centered">
        <img src="../assets/oh_no.jpg" alt="Not found 'oh no' picture">
        <h1 class="title">
          <translate>The page you're looking for doesn't exist.</translate>
        </h1>
        <p>
          <translate>Please make sure the address is correct and that the page hasn't been moved.</translate>
        </p>
        <p>
          <translate>Please contact this instance's Mobilizon admin if you think this is a mistake.</translate>
        </p>
        <!--  The following should just be replaced with the SearchField component but it fails for some reason  -->
        <form @submit="enter">
          <b-field class="search">
            <b-input expanded icon="magnify" type="search" :placeholder="searchPlaceHolder" v-model="searchText" />
            <p class="control">
              <button type="submit" class="button is-primary"><translate>Search</translate></button>
            </p>
          </b-field>
        </form>
      </div>
    </div>
  </section>
</template>
<script lang="ts">
import { Component, Vue } from 'vue-property-decorator';
import { RouteName } from '@/router';
import BField from 'buefy/src/components/field/Field.vue';

@Component({
  components: {
    BField,
  },
})
export default class PageNotFound extends Vue {
  searchText: string = '';

  get searchPlaceHolder(): string {
    return this.$gettext('Search events, groups, etc.');
  }

  enter() {
    this.$router.push({ name: RouteName.SEARCH, params: { searchTerm: this.searchText } });
  }
}
</script>
<style lang="scss">
  .container.not-found {
    margin: auto;
    max-width: 600px;

    img {
      margin-top: 3rem;
    }

    p {
      margin-bottom: 1em;
    }
  }
</style>
