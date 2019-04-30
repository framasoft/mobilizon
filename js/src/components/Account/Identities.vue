<template>
  <section>
    <h1 class="title">
      <translate>My identities</translate>
    </h1>

    <ul class="identities">
      <li v-for="identity in identities" :key="identity.id">
        <div class="media identity" v-bind:class="{ 'is-current-identity': isCurrentIdentity(identity) }">
          <div class="media-left">
            <figure class="image is-48x48">
              <img class="is-rounded" :src="identity.avatarUrl">
            </figure>
          </div>

          <div class="media-content">
            {{ identity.displayName() }}
          </div>
        </div>
      </li>
    </ul>

    <a class="button create-identity is-primary">
      <translate>Create a new identity</translate>
    </a>
  </section>
</template>

<style lang="scss" scoped>
  .identities {
    border-right: 1px solid grey;

    padding: 15px 0;
  }

  .media.identity {
    align-items: center;
    font-size: 1.3rem;
    padding-bottom: 0;
    margin-bottom: 15px;

    &.is-current-identity {
      background-color: rgba(0, 0, 0, 0.1);
    }
  }

  .title {
    margin-bottom: 30px;
  }
</style>

<script lang="ts">
  import { Component, Vue } from 'vue-property-decorator';
  import { IDENTITIES, LOGGED_PERSON } from '@/graphql/actor';
  import { IPerson, Person } from '@/types/actor';

  @Component({
    apollo: {
      loggedPerson: {
        query: LOGGED_PERSON,
      },
    },
  })
  export default class Identities extends Vue {
    identities: Person[] = [];
    loggedPerson!: IPerson;
    errors: string[] = [];

    async mounted() {
      const result = await this.$apollo.query({
        query: IDENTITIES,
      });

      this.identities = result.data.identities
                              .map(i => new Person(i));
    }

    isCurrentIdentity(identity: IPerson) {
      return identity.preferredUsername === this.loggedPerson.preferredUsername;
    }
  }
</script>
