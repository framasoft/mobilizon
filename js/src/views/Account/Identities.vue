<template>
  <section>
    <b-loading :active.sync="$apollo.loading"></b-loading>
    <h1 class="title">
      <translate>Identities</translate>
    </h1>
    <a class="button is-primary" @click="showCreateProfileForm = true">
      <translate>Add a new profile</translate>
    </a>
    <div class="columns" v-if="showCreateProfileForm">
      <form @submit="createProfile" class="column is-half">
        <b-message title="Error" type="is-danger" v-for="error in errors" :key="error">{{ error }}</b-message>
        <b-field label="Username">
          <b-input aria-required="true" required v-model="newPerson.preferredUsername"/>
        </b-field>
        <button class="button is-primary">
          <translate>Register</translate>
        </button>
      </form>
    </div>
    <ul>
      <li v-for="identity in identities" :key="identity.id">
        <hr>
        <div class="media">
          <div class="media-left">
            <figure class="image is-48x48">
              <img :src="identity.avatarUrl">
            </figure>
          </div>
          <div class="media-content">
            <p class="title is-5">
              {{ identity.name }}
              <span
                v-if="identity.preferredUsername === loggedPerson.preferredUsername"
                class="tag is-primary"
              >
                <translate>Current</translate>
              </span>
            </p>
            <p class="subtitle is-6">@{{ identity.preferredUsername }}</p>
          </div>
        </div>
      </li>
    </ul>
  </section>
</template>

<script lang="ts">
import { Component, Vue } from "vue-property-decorator";
import { IDENTITIES, LOGGED_PERSON, CREATE_PERSON } from "../../graphql/actor";
import { IPerson } from "@/types/actor.model";

@Component({
  apollo: {
    identities: {
      query: IDENTITIES
    },
    loggedPerson: {
      query: LOGGED_PERSON
    }
  }
})
export default class Identities extends Vue {
  identities: IPerson[] = [];
  loggedPerson!: IPerson;
  newPerson!: IPerson;
  showCreateProfileForm: boolean = false;
  errors: string[] = [];

  async createProfile(e) {
    e.preventDefault();

    try {
      await this.$apollo.mutate({
        mutation: CREATE_PERSON,
        variables: this.newPerson
      });
      this.showCreateProfileForm = false;
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
