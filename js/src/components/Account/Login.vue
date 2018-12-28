<template>
  <v-container fluid fill-height>
    <v-layout align-center justify-center>
      <v-flex xs12 sm8 md4>
        <v-card class="elevation-12">
          <v-toolbar dark color="primary">
            <v-toolbar-title>Login</v-toolbar-title>
            <v-spacer></v-spacer>
            <v-tooltip bottom>
              <v-btn
                slot="activator"
                :to="{ name: 'Register', params: { email: this.credentials.email, password: this.credentials.password } }"
              >
                <!-- <v-icon large>login</v-icon> -->
                <span>Register</span>
              </v-btn>
              <span>Register</span>
            </v-tooltip>
          </v-toolbar>
          <v-card-text>
            <div class="text-xs-center">
              <v-avatar size="80px">
                <transition name="avatar">
                  <component :is="validEmail()" v-bind="{email: credentials.email}"></component>
                  <!-- <v-gravatar :email="credentials.email" default-img="mp" v-if="validEmail()"/>
                  <avatar v-else></avatar> -->
                </transition>
              </v-avatar>
            </div>
            <v-form @submit="loginAction" v-if="!validationSent">
              <v-text-field
                label="Email"
                required
                type="text"
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
              <v-btn @click="loginAction" color="blue">Login</v-btn>
              <router-link :to="{ name: 'SendPasswordReset', params: { email: credentials.email } }">Password forgotten ?</router-link>
            </v-form>
            <div v-else>
              <h2>{{ $t('registration.form.validation_sent', { email: credentials.email }) }}</h2>
              <b-alert show variant="info">{{ $t('registration.form.validation_sent_info') }}</b-alert>
            </div>
          </v-card-text>
        </v-card>
      </v-flex>
    </v-layout>
  </v-container>
</template>

<script lang="ts">

  import Gravatar from 'vue-gravatar';
  import RegisterAvatar from './RegisterAvatar.vue';
  import { AUTH_TOKEN, AUTH_USER_ACTOR, AUTH_USER_ID } from '@/constants';
  import { Component, Prop, Vue } from 'vue-property-decorator';
  import { LOGIN } from '@/graphql/auth';

  @Component({
    components: {
      'v-gravatar': Gravatar,
      avatar: RegisterAvatar,
    },
  })
  export default class Login extends Vue {
    @Prop({ type: String, required: false, default: '' }) email!: string;
    @Prop({ type: String, required: false, default: '' }) password!: string;

    credentials = {
      email: '',
      password: '',
    };
    validationSent = false;
    error = {
      show: false,
      text: '',
      timeout: 3000,
      field: {
        email: false,
        password: false,
      },
    };
    rules = {
      required: value => !!value || 'Required.',
      email: (value) => {
        const pattern = /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
        return pattern.test(value) || 'Invalid e-mail.';
      },
    };
    user: any;

    beforeCreate() {
      if (this.user) {
        this.$router.push('/');
      }
    }

    mounted() {
      this.credentials.email = this.email;
      this.credentials.password = this.password;
    }

    async loginAction(e: Event) {
      e.preventDefault();

      try {
        const result = await this.$apollo.mutate({
          mutation: LOGIN,
          variables: {
            email: this.credentials.email,
            password: this.credentials.password,
          },
        });

        this.saveUserData(result.data);
        this.$router.push({ name: 'Home' });
      } catch (err) {
        console.error(err);
        this.error.show = true;
        this.error.text = err.message;
      }
    }

    validEmail() {
      return this.rules.email(this.credentials.email) === true ? 'v-gravatar' : 'avatar';
    }

    saveUserData({ login: login }) {
      localStorage.setItem(AUTH_USER_ID, login.user.id);
      localStorage.setItem(AUTH_TOKEN, login.token);
    }
  }
</script>
