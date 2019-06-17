<template>
  <section class="container">
    <div v-if="loggedPerson">
      <div class="header">
        <figure v-if="loggedPerson.banner" class="image is-3by1">
          <img :src="loggedPerson.banner.url" alt="banner">
        </figure>
      </div>

      <div class="columns">
        <div class="identities column is-4">
          <identities v-bind:currentIdentityName="currentIdentityName"></identities>
        </div>
        <div class="column is-8">
          <router-view></router-view>
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
import { Component, Vue, Watch } from 'vue-property-decorator';
import EventCard from '@/components/Event/EventCard.vue';
import { IPerson } from '@/types/actor';
import Identities from '@/components/Account/Identities.vue';

@Component({
  components: {
    EventCard,
    Identities,
  },
})
export default class MyAccount extends Vue {
  loggedPerson: IPerson | null = null;
  currentIdentityName: string | null = null;

  @Watch('$route.params.identityName', { immediate: true })
  async onIdentityParamChanged (val: string) {
    if (!this.loggedPerson) {
      this.loggedPerson = await this.loadLoggedPerson();
    }

    await this.redirectIfNoIdentitySelected(val);

    this.currentIdentityName = val;
  }

  private async redirectIfNoIdentitySelected (identityParam?: string) {
    if (!!identityParam) return;

    if (!!this.loggedPerson) {
      this.$router.push({ params: { identityName: this.loggedPerson.preferredUsername } });
    }
  }

  private async loadLoggedPerson () {
    const result = await this.$apollo.query({
      query: LOGGED_PERSON,
    });

    return result.data.loggedPerson as IPerson;
  }
}
</script>
<style lang="scss">
  @import "../../variables";
  @import "~bulma/sass/utilities/_all";
  @import "~bulma/sass/components/dropdown.sass";
</style>
