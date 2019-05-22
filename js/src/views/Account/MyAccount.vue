<template>
  <section class="container">
    <div v-if="person">
      <div class="header">
        <figure v-if="person.banner" class="image is-3by1">
          <img :src="person.banner.url" alt="banner">
        </figure>
      </div>

      <div class="columns">
        <div class="identities column is-4">
          <identities></identities>
        </div>
      </div>
    </div>
  </section>
</template>

<style lang="scss">
  .header {
    padding-bottom: 30px;
  }

  .identities {
    padding-right: 45px;
    margin-right: 45px;
  }
</style>

<script lang="ts">
import { LOGGED_PERSON } from '@/graphql/actor';
import { Component, Vue } from 'vue-property-decorator';
import EventCard from '@/components/Event/EventCard.vue';
import { IPerson } from '@/types/actor';
import { CURRENT_USER_CLIENT } from '@/graphql/user';
import Identities from '@/components/Account/Identities.vue';

@Component({
  apollo: {
    currentUser: {
      query: CURRENT_USER_CLIENT,
    },
    loggedPerson: {
      query: LOGGED_PERSON,
    },
  },
  components: {
    EventCard,
    Identities,
  },
})
export default class MyAccount extends Vue {
  person: IPerson | null = null;

  async mounted () {
    const result = await this.$apollo.query({
      query: LOGGED_PERSON,
    });

    this.person = result.data.loggedPerson;
  }
}
</script>
<style lang="scss">
  @import "../../variables";
  @import "~bulma/sass/utilities/_all";
  @import "~bulma/sass/components/dropdown.sass";
</style>
