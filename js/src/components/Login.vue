<template>
  <div>
  <v-form>
    <v-text-field
      label="Email"
      required
      type="text"
      v-model="credentials.email"
      :rules="[rules.required]"
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
    <v-btn @click="loginAction" color="blue">Login</v-btn>
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

    beforeCreate() {
      if (this.$store.state.user) {
        this.$router.push('/');
      }
    },

    data() {
      return {
        credentials: {
          email: '',
          password: '',
        },
        error: {
          show: false,
          text: '',
          timeout: 3000,
          field: {
            email: false,
            password: false,
          },
        },
        rules: {
          required: value => !!value || 'Required.',
        },
      };
    },
    methods: {
      loginAction(e) {
        e.preventDefault();
        auth.login(JSON.stringify(this.credentials), this.$store, '/', (error) => {
          this.error.show = true;
          this.error.text = error.message;
          this.error.field[error.field] = true;
        });
      },
    },
  };
</script>
