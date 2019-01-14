<template>
  <v-container fluid fill-height>
    <v-layout align-center justify-center>
      <v-flex xs12 sm8 md4>
        <v-card class="elevation-12">
          <v-toolbar dark color="primary">
            <v-toolbar-title>Password Reset</v-toolbar-title>
          </v-toolbar>
          <v-card-text>
            <v-alert type="error" :value="state.token.status === false">{{ state.token.msg }}</v-alert>
            <v-form @submit="resetAction">
              <v-text-field
                label="Password"
                type="password"
                v-model="credentials.password"
                required
                :error="state.password.status"
                :rules="[rules.required, rules.password_length]"
              >
              </v-text-field>
              <v-text-field
                label="Password (confirmation)"
                type="password"
                v-model="credentials.password_confirmation"
                required
                :rules="[rules.required, rules.password_length, rules.password_equal]"
                :error="state.password_confirmation.status"
              >
              </v-text-field>
              <v-btn type="submit" :disabled="!samePasswords" color="blue">Reset my password</v-btn>
            </v-form>
          </v-card-text>
        </v-card>
      </v-flex>
    </v-layout>
  </v-container>
</template>

<script lang="ts">

  import { Component, Prop, Vue } from 'vue-property-decorator';
  import { validateRequiredField } from '@/utils/validators';
  import { RESET_PASSWORD } from '@/graphql/auth';
  import { saveUserData } from '@/utils/auth';
  import { ILogin } from '@/types/login.model'

  @Component
  export default class PasswordReset extends Vue {
    @Prop({ type: String, required: true }) token!: string;

    credentials = {
      password: '',
      password_confirmation: '',
    };
    error = {
      show: false,
    };
    state = {
      token: {
        status: null,
        msg: '',
      },
      password: {
        status: null,
        msg: '',
      },
      password_confirmation: {
        status: null,
        msg: '',
      },
    };
    rules = {
      password_length: value => value.length > 6 || 'Password must be at least 6 characters long',
      required: validateRequiredField,
      password_equal: value => value === this.credentials.password || 'Passwords must be the same',
    };

    get samePasswords() {
      return this.rules.password_length(this.credentials.password) === true &&
        this.credentials.password === this.credentials.password_confirmation;
    }

    async resetAction(e) {
      this.resetState();
      this.error.show = false;

      e.preventDefault();

      try {
        const result = await this.$apollo.mutate<{ resetPassword: ILogin}>({
          mutation: RESET_PASSWORD,
          variables: {
            password: this.credentials.password,
            token: this.token,
          },
        });

        saveUserData(result.data.resetPassword);
        this.$router.push({ name: 'Home' });
      } catch (err) {
        console.error(err);
        this.error.show = true;
      }
    }

    resetState() {
      this.state = {
        token: {
          status: null,
          msg: '',
        },
        password_confirmation: {
          status: null,
          msg: '',
        },
        password: {
          status: null,
          msg: '',
        },
      };
    }
  };
</script>
