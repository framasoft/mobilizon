<template>
  <v-container fluid fill-height>
    <v-layout align-center justify-center>
      <v-flex xs12 sm8 md4>
        <v-card class="elevation-12">
          <v-toolbar dark color="primary">
            <v-toolbar-title>Password Reset</v-toolbar-title>
          </v-toolbar>
          <v-card-text>
            <v-form @submit="resendConfirmationAction" v-if="!validationSent">
              <v-text-field
                label="Email"
                type="email"
                v-model="credentials.email"
                required
                :state="state.email.status"
                :rules="[rules.required, rules.email]"
              >
              </v-text-field>
              <v-btn type="submit" color="blue">Reset my password</v-btn>
            </v-form>
            <div v-else>
              <h2>Validation email sent to {{ credentials.email }}</h2>
              <v-alert :value="true" type="info">Please check you spam folder if you didn't receive the email.</v-alert>
            </div>
          </v-card-text>
        </v-card>
      </v-flex>
    </v-layout>
  </v-container>
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
    };
    validationSent = false;
    error = false;
    state = {
      email: {
        status: null,
        msg: '',
      } as { status: boolean | null, msg: string },
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
          mutation: SEND_RESET_PASSWORD,
          variables: {
            email: this.credentials.email,
          },
        });

        this.validationSent = true;
      } catch (err) {
        console.error(err);
        this.error = true;
        this.state.email = { status: false, msg: err.errors };
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
  };
</script>
