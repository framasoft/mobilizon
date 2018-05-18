<template>
  <div>
  <v-form>
    <v-text-field
      label="Username"
      required
      type="text"
      v-model="credentials.username"
      :rules="[rules.required]"
    >
    </v-text-field>
    <v-text-field
      label="email"
      required
      type="email"
      v-model="credentials.email"
      :rules="[rules.required, rules.email]"
    >
    </v-text-field>
    <v-text-field
      label="password"
      required
      type="password"
      v-model="credentials.password"
      :rules="[rules.required]"
    >
    </v-text-field>
    <v-btn @click="registerAction" color="primary">Register</v-btn>
  </v-form>
  <v-snackbar
    :timeout="error.timeout"
    :error="true"
    v-model="error.show"
  >
    {{ error.text }}
    <v-btn dark flat @click.native="error.show = false">Close</v-btn>
  </v-snackbar>
  </div>
</template>

<script>

  import auth from '@/auth/index';

  export default {
    data() {
      return {
        credentials: {
          username: '',
          email: '',
          password: '',
        },
        error: {
          show: false,
          text: '',
          timeout: 3000,
          field: {
            username: false,
            email: false,
            password: false,
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
      registerAction(e) {
        e.preventDefault();
        auth.signup(JSON.stringify(this.credentials), (response) => {
          console.log(response);
          this.$store.commit('LOGIN_USER', response.user);
          this.$router.push({ name: 'Home' });
        }, (error) => {
          this.error.show = true;
          this.error.text = error.message;
          this.error.field[error.field] = true;
        });
      },
    },
  };
</script>
