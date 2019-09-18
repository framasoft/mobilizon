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
            <div class="content">
              <h3 class="title">{{ $t('Features') }}</h3>
              <ul>
                <li>{{ $t('Create your communities and your events') }}</li>
                <li>{{ $t('Other stuff…') }}</li>
              </ul>
            </div>
            <i18n path="Learn more on" tag="p">
              <a target="_blank" href="https://joinmobilizon.org">joinmobilizon.org</a>
            </i18n>
            <hr>
            <div class="content">
              <h3 class="title">{{ $t('About this instance') }}</h3>
              <p>
                {{ $t("Your local administrator resumed it's policy:") }}
              </p>
              <ul>
                <li>{{ $t('Please be nice to each other') }}</li>
                <li>{{ $t('meditate a bit') }}</li>
              </ul>
              <p>
                {{ $t('Please read the full rules') }}
              </p>
            </div>
          </div>
          <div class="column">
            <form @submit="submit">
              <b-field
                :label="$t('Email')"
                :type="errors.email ? 'is-danger' : null"
                :message="errors.email"
              >
                <b-input
                  aria-required="true"
                  required
                  type="email"
                  v-model="credentials.email"
                  @blur="showGravatar = true"
                  @focus="showGravatar = false"
                />
              </b-field>

              <b-field
                :label="$t('Password')"
                :type="errors.password ? 'is-danger' : null"
                :message="errors.password"
              >
                <b-input
                  aria-required="true"
                  required
                  type="password"
                  password-reveal
                  minlength="6"
                  v-model="credentials.password"
                />
              </b-field>

              <b-field grouped>
                <div class="control">
                  <button type="button" class="button is-primary" @click="submit()">
                    {{ $t('Register') }}
                  </button>
                </div>
                <div class="control">
                  <router-link
                    class="button is-text"
                    :to="{ name: 'ResendConfirmation', params: { email: credentials.email }}"
                  >
                    {{ $t("Didn't receive the instructions ?") }}
                  </router-link>
                </div>
                <div class="control">
                  <router-link
                    class="button is-text"
                    :to="{ name: 'Login', params: { email: credentials.email, password: credentials.password }}"
                    :disabled="sendingValidation"
                  >
                    {{ $t('Login') }}
                  </router-link>
                </div>
              </b-field>
            </form>

            <div v-if="errors.length > 0">
              <b-message type="is-danger" v-for="error in errors" :key="error">{{ error }}</b-message>
            </div>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<script lang="ts">
import { CREATE_USER } from '@/graphql/user';
import { Component, Prop, Vue } from 'vue-property-decorator';
import { UserRouteName } from '@/router/user';

@Component
export default class Register extends Vue {
  @Prop({ type: String, required: false, default: '' }) email!: string;
  @Prop({ type: String, required: false, default: '' }) password!: string;

  credentials = {
    email: this.email,
    password: this.password,
  };
  errors: object = {};
  sendingValidation: boolean = false;
  validationSent: boolean = false;

  async submit() {
    try {
      this.sendingValidation = true;
      this.errors = {};

      await this.$apollo.mutate({
        mutation: CREATE_USER,
        variables: this.credentials,
      });

      this.validationSent = true;

      this.$router.push({
        name: UserRouteName.REGISTER_PROFILE,
        params: { email: this.credentials.email },
      });
    } catch (error) {
      console.error(error);
      this.errors = error.graphQLErrors.reduce((acc, error) => {
        acc[error.details] = error.message;
        return acc;
      },                                       {});
      console.log(this.errors);
    }
  }
}
</script>

<style lang="scss">
  @import "../../variables";

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

  h3.title {
    background: $secondary;
    display: inline;
  }
</style>
