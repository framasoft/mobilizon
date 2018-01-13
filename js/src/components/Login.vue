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
        auth.login(JSON.stringify(this.credentials), (data) => {
          this.$store.commit('LOGIN_USER', data.user);
          this.$router.push({ name: 'Home' });
        }, (error) => {
          Promise.resolve(error).then((errorMsg) => {
            console.log(errorMsg);
            this.error.show = true;
            this.error.text = this.$t(errorMsg.display_error);
          }).catch((e) => {
            console.log(e);
            this.error.show = true;
            this.error.text = e.message;
          });
        });
      },
    },
  };
</script>
