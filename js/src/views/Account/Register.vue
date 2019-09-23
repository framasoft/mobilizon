<template>
  <div>
    <section class="hero">
      <div class="hero-body">
        <h1 class="title">
          {{ $t('Register an account on Mobilizon!') }}
        </h1>
      </div>
    </section>
    <section>
      <div class="container">
        <div class="columns is-mobile">
          <div class="column">
            <form v-if="!validationSent">
              <b-field
                :label="$t('Username')"
                :type="errors.preferred_username ? 'is-danger' : null"
                :message="errors.preferred_username"
              >
                <b-field>
                  <b-input
                    aria-required="true"
                    required
                    expanded
                    v-model="person.preferredUsername"
                  />
                  <p class="control">
                    <span class="button is-static">@{{ host }}</span>
                  </p>
                </b-field>
              </b-field>

              <b-field :label="$t('Displayed name')">
                <b-input v-model="person.name"/>
              </b-field>

              <b-field :label="$t('Description')">
                <b-input type="textarea" v-model="person.summary"/>
              </b-field>

              <b-field grouped>
                <div class="control">
                  <button type="button" class="button is-primary" @click="submit()">
                     {{ $t('Create my profile') }}
                  </button>
                </div>
              </b-field>
            </form>

            <div v-if="validationSent && !userAlreadyActivated">
              <b-message title="Success" type="is-success">
                <h2 class="title">
                  {{ $t('Your account is nearly ready, {username}', { username: person.preferredUsername }) }}
                </h2>
                <p>
                  {{ $t('A validation email was sent to {email}', { email }) }}
                </p>
                <p>
                  {{ $t('Before you can login, you need to click on the link inside it to validate your account') }}
                </p>
              </b-message>
            </div>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<script lang="ts">
import { Component, Prop, Vue } from 'vue-property-decorator';
import { IPerson } from '@/types/actor';
import { REGISTER_PERSON } from '@/graphql/actor';
import { MOBILIZON_INSTANCE_HOST } from '@/api/_entrypoint';
import { RouteName } from '@/router';

@Component
export default class Register extends Vue {
  @Prop({ type: String, required: true }) email!: string;
  @Prop({ type: Boolean, required: false, default: false }) userAlreadyActivated!: boolean;

  host?: string = MOBILIZON_INSTANCE_HOST;

  person: IPerson = {
    preferredUsername: '',
    name: '',
    summary: '',
    url: '',
    suspended: false,
    avatar: null,
    banner: null,
    domain: null,
    feedTokens: [],
    goingToEvents: [],
  };
  errors: object = {};
  validationSent: boolean = false;
  sendingValidation: boolean = false;

  async submit() {
    try {
      this.sendingValidation = true;
      this.errors = {};
      await this.$apollo.mutate({
        mutation: REGISTER_PERSON,
        variables: Object.assign({ email: this.email }, this.person),
      });
      this.validationSent = true;

      if (this.userAlreadyActivated) {
        this.$router.push({ name: RouteName.HOME });
      }
    } catch (error) {
      this.errors = error.graphQLErrors.reduce((acc, error) => {
        acc[error.details] = error.message;
        return acc;
      },                                       {});
      console.error(error);
      console.error(this.errors);
    }
  }
}
</script>

<style lang="scss">
.avatar-enter-active {
  transition: opacity 1s ease;
}

.avatar-enter,
.avatar-leave-to {
  opacity: 0;
}

.avatar-leave {
  display: none;
}
</style>
