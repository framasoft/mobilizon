<template>
  <v-container fluid fill-height>
    <v-layout align-center justify-center>
      <v-flex xs12 sm8 md4>
        <v-card class="elevation-12">
          <v-toolbar dark color="primary">
            <v-toolbar-title>Register</v-toolbar-title>
            <v-spacer></v-spacer>
            <v-tooltip bottom>
              <v-btn
                slot="activator"
                :to="{ name: 'Login', params: { email, password } }"
              >
                <!-- <v-icon large>login</v-icon> -->
                <span>Login</span>
              </v-btn>
              <span>Login</span>
            </v-tooltip>
          </v-toolbar>
          <v-card-text>
            <div class="text-xs-center">
              <v-avatar size="80px">
                <transition name="avatar">
                  <component :is="validEmail()" v-bind="{email}"></component>
                  <!-- <v-gravatar :email="credentials.email" default-img="mp" v-if="validEmail()"/>
                  <avatar v-else></avatar> -->
                </transition>
              </v-avatar>
            </div>
            <v-form @submit="submit()" v-if="!validationSent">
              <v-text-field
                label="Username"
                required
                type="text"
                v-model="username"
                :rules="[rules.required]"
                :error="state.username.status"
                :error-messages="state.username.msg"
                :suffix="host()"
                hint="You will be able to create more identities once registered"
                persistent-hint
              >
              </v-text-field>
              <v-text-field
                label="Email"
                required
                type="email"
                ref="email"
                v-model="email"
                :rules="[rules.required, rules.email]"
                :error="state.email.status"
                :error-messages="state.email.msg"
              >
              </v-text-field>
              <v-text-field
                label="Password"
                required
                :type="showPassword ? 'text' : 'password'"
                v-model="password"
                :rules="[rules.required, rules.password_length]"
                :error="state.password.status"
                :error-messages="state.password.msg"
                :append-icon="showPassword ? 'visibility_off' : 'visibility'"
                @click:append="showPassword = !showPassword"
              >
              </v-text-field>
              <v-btn @click="submit()" color="primary">Register</v-btn>
              <router-link :to="{ name: 'ResendConfirmation', params: { email }}">Didn't receive the instructions ?</router-link>
            </v-form>
            <div v-if="validationSent">
              <h2><translate>A validation email was sent to %{email}</translate></h2>
              <v-alert :value="true" type="info"><translate>Before you can login, you need to click on the link inside it to validate your account</translate></v-alert>
            </div>
          </v-card-text>
        </v-card>
      </v-flex>
    </v-layout>
  </v-container>
</template>

<script>
import Gravatar from 'vue-gravatar';
import RegisterAvatar from './RegisterAvatar';
import { CREATE_USER } from '@/graphql/user';

export default {
  props: {
    default_email: {
      type: String,
      required: false,
      default: '',
    },
    default_password: {
      type: String,
      required: false,
      default: '',
    },
  },
  components: {
    'v-gravatar': Gravatar,
    avatar: RegisterAvatar,
  },
  data() {
    return {
      username: '',
      email: this.default_email,
      password: this.default_password,
      error: {
        show: false,
      },
      showPassword: false,
      validationSent: false,
      state: {
        email: {
          status: false,
          msg: [],
        },
        username: {
          status: false,
          msg: [],
        },
        password: {
          status: false,
          msg: [],
        },
      },
      rules: {
        password_length: value => value.length > 6 || 'Password must be at least 6 caracters long',
        required: value => !!value || 'Required.',
        email: (value) => {
          const pattern = /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
          return pattern.test(value) || 'Invalid e-mail.';
        },
      },
    };
  },
  methods: {
    resetState() {
      this.state = {
        email: {
          status: false,
          msg: '',
        },
        username: {
          status: false,
          msg: '',
        },
        password: {
          status: false,
          msg: '',
        },
      };
    },
    host() {
      return `@${window.location.host}`;
    },
    validEmail() {
      return this.rules.email(this.email) === true ? 'v-gravatar' : 'avatar';
    },
    submit() {
      this.$apollo.mutate({
        mutation: CREATE_USER,
        variables: {
          email: this.email,
          password: this.password,
          username: this.username,
        },
      }).then((data) => {
        console.log(data);
        this.validationSent = true;
      }).catch((error) => {
        console.error(error);
      });
    },
  },
};
</script>
<style lang="scss">
.avatar-enter-active {
  transition: opacity 1s ease;
}
.avatar-enter, .avatar-leave-to {
  opacity: 0;
}

.avatar-leave {
  display: none;
}
</style>
