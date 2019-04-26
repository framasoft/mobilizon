<template>
  <!-- TODO -->
</template>

<script lang="ts">
  import { Component, Vue } from 'vue-property-decorator';
  import { CREATE_PERSON, LOGGED_PERSON } from '../../graphql/actor';
  import { IPerson } from '@/types/actor';

  @Component({
    apollo: {
      loggedPerson: {
        query: LOGGED_PERSON,
      },
    },
  })
  export default class Identities extends Vue {
    loggedPerson!: IPerson;
    errors: string[] = [];
    newPerson!: IPerson;

    async createProfile(e) {
      e.preventDefault();

      try {
        await this.$apollo.mutate({
          mutation: CREATE_PERSON,
          variables: this.newPerson,
        });

        this.$apollo.queries.identities.refresh();
      } catch (err) {
        console.error(err);
        err.graphQLErrors.forEach(({ message }) => {
          this.errors.push(message);
        });
      }
    }

    host() {
      return `@${window.location.host}`;
    }
  }
</script>
