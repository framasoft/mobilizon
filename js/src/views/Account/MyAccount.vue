<template>
  <section class="container">
    <div v-if="currentActor">
      <div class="header">
        <figure v-if="currentActor.banner" class="image is-3by1">
          <img :src="currentActor.banner.url" alt="banner">
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
import { CURRENT_ACTOR_CLIENT } from '@/graphql/actor';
import { Component, Vue, Watch } from 'vue-property-decorator';
import EventCard from '@/components/Event/EventCard.vue';
import { IPerson } from '@/types/actor';
import Identities from '@/components/Account/Identities.vue';

@Component({
  components: {
    EventCard,
    Identities,
  },
  apollo: {
    currentActor: {
      query: CURRENT_ACTOR_CLIENT,
    },
  },
})
export default class MyAccount extends Vue {
  currentActor!: IPerson;
  currentIdentityName: string | null = null;

  @Watch('$route.params.identityName', { immediate: true })
  async onIdentityParamChanged (val: string) {
    await this.redirectIfNoIdentitySelected(val);

    this.currentIdentityName = val;
  }

  private async redirectIfNoIdentitySelected (identityParam?: string) {
    if (!!identityParam) return;

    if (!!this.currentActor) {
      await this.$router.push({ params: { identityName: this.currentActor.preferredUsername } });
    }
  }
}
</script>
<style lang="scss">
  @import "../../variables";
  @import "~bulma/sass/utilities/_all";
  @import "~bulma/sass/components/dropdown.sass";
</style>
