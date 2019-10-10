<template>
  <section class="container">
    <div class="columns is-mobile is-centered">
      <div class="column is-half-desktop">
        <h1 class="title">
          {{ $t('Resend confirmation email') }}
        </h1>
        <form v-if="!validationSent" @submit="resendConfirmationAction">
          <b-field label="Email">
            <b-input aria-required="true" required type="email" v-model="credentials.email"/>
          </b-field>
          <p class="control has-text-centered">
            <b-button type="is-primary">
            {{ $t('Send me the confirmation email once again') }}
            </b-button>
          </p>
        </form>
        <div v-else>
          <b-message type="is-success" :closable="false" title="Success">
            {{ $t('If an account with this email exists, we just sent another confirmation email to {email}', {email: credentials.email}) }}
          </b-message>
          <b-message type="is-info">
            {{ $t("Please check your spam folder if you didn't receive the email.") }}
          </b-message>
        </div>
      </div>
    </div>
  </section>
</template>

<script lang="ts">
import { Component, Prop, Vue } from 'vue-property-decorator';
import { validateEmailField, validateRequiredField } from '@/utils/validators';
import { RESEND_CONFIRMATION_EMAIL } from '@/graphql/auth';

@Component
export default class ResendConfirmation extends Vue {
  @Prop({ type: String, required: false, default: '' }) email!: string;

  credentials = {
    email: '',
  };
  validationSent = false;
  error = false;
  state = {
    email: {
      status: null,
      msg: '',
    },
  };
  rules = {
    required: validateRequiredField,
    email: validateEmailField,
  };

  mounted() {
    this.credentials.email = this.email;
  }

  async resendConfirmationAction(e) {
    e.preventDefault();
    this.error = false;

    try {
      await this.$apollo.mutate({
        mutation: RESEND_CONFIRMATION_EMAIL,
        variables: {
          email: this.credentials.email,
        },
      });
    } catch (err) {
      console.error(err);
      this.error = true;
    } finally {
      this.validationSent = true;
    }
  }
}
</script>

<style lang="scss" scoped>
  .container .columns {
    margin: 1rem auto 3rem;
  }
</style>