<template>
  <section class="container">
    <div class="column">
      <h1 class="title">
        {{ $t('Password reset') }}
      </h1>
      <b-message title="Error" type="is-danger" v-for="error in errors" :key="error">{{ error }}</b-message>
      <form @submit="sendResetPasswordTokenAction" v-if="!validationSent">
        <b-field label="Email">
          <b-input aria-required="true" required type="email" v-model="credentials.email"/>
        </b-field>
        <button class="button is-primary">
          {{ $t('Send email to reset my password') }}
        </button>
      </form>
      <div v-else>
        <b-message type="is-success" :closable="false" title="Success">
          {{ $t('We just sent an email to {email}', {email: credentials.email}) }}
        </b-message>
        <b-message type="is-info">
          {{ $t("Please check your spam folder if you didn't receive the email.") }}
        </b-message>
      </div>
    </div>
  </section>
</template>

<script lang="ts">
import { Component, Prop, Vue } from 'vue-property-decorator';
import { validateEmailField, validateRequiredField } from '@/utils/validators';
import { SEND_RESET_PASSWORD } from '@/graphql/auth';

@Component
export default class SendPasswordReset extends Vue {
  @Prop({ type: String, required: false, default: '' }) email!: string;

  credentials = {
    email: '',
  } as { email: string };
  validationSent: boolean = false;
  errors: string[] = [];
  state = {
    email: {
      status: null,
      msg: '',
    } as { status: boolean | null; msg: string },
  };

  rules = {
    required: validateRequiredField,
    email: validateEmailField,
  };

  mounted() {
    this.credentials.email = this.email;
  }

  async sendResetPasswordTokenAction(e) {
    e.preventDefault();

    try {
      await this.$apollo.mutate({
        mutation: SEND_RESET_PASSWORD,
        variables: {
          email: this.credentials.email,
        },
      });

      this.validationSent = true;
    } catch (err) {
      console.error(err);
      err.graphQLErrors.forEach(({ message }) => {
        this.errors.push(message);
      });
    }
  }

  resetState() {
    this.state = {
      email: {
        status: null,
        msg: '',
      },
    };
  }
}
</script>
