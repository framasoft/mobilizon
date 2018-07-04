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

<script>
import fetchStory from '@/api/eventFetch';

export default {
  name: 'SendPasswordReset',
  props: {
    email: {
      type: String,
      required: false,
      default: '',
    },
  },
  mounted() {
      this.credentials.email = this.email;
    },
  data() {
    return {
      credentials: {
        email: '',
      },
      validationSent: false,
      error: false,
      state: {
        email: {
          status: null,
          msg: '',
        },
      },
      rules: {
        required: value => !!value || 'Required.',
        email: (value) => {
          const pattern = /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
          return pattern.test(value) || 'Invalid e-mail.';
        },
      },
    };
  },
  methods: {
    resendConfirmationAction(e) {
      e.preventDefault();
      fetchStory('/users/password-reset/send', this.$store, { method: 'POST', body: JSON.stringify(this.credentials) }).then(() => {
        this.error = false;
        this.validationSent = true;
      }).catch((err) => {
        Promise.resolve(err).then((data) => {
          this.error = true;
          this.state.email = { status: false, msg: data.errors };
        });
      });
    },
    resetState() {
      this.state = {
        email: {
          status: null,
          msg: '',
        },
      };
    },
  },
};
</script>
