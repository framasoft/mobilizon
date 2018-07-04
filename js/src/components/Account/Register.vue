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
                :to="{ name: 'Login', params: { email: this.credentials.email, password: this.credentials.password } }"
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
                  <component :is="validEmail()" v-bind="{email: credentials.email}"></component>
                  <!-- <v-gravatar :email="credentials.email" default-img="mp" v-if="validEmail()"/>
                  <avatar v-else></avatar> -->
                </transition>
              </v-avatar>
            </div>
            <v-form @submit="registerAction" v-if="!validationSent">
              <v-text-field
                label="Username"
                required
                type="text"
                v-model="credentials.username"
                :rules="[rules.required]"
                :error="this.state.username.status"
                :error-messages="this.state.username.msg"
                :suffix="this.host()"
                hint="You will be able to create more identities once registered"
                persistent-hint
              >
              </v-text-field>
              <v-text-field
                label="Email"
                required
                type="email"
                ref="email"
                v-model="credentials.email"
                :rules="[rules.required, rules.email]"
                :error="this.state.email.status"
                :error-messages="this.state.email.msg"
              >
              </v-text-field>
              <v-text-field
                label="Password"
                required
                :type="showPassword ? 'text' : 'password'"
                v-model="credentials.password"
                :rules="[rules.required, rules.password_length]"
                :error="this.state.password.status"
                :error-messages="this.state.password.msg"
                :append-icon="showPassword ? 'visibility_off' : 'visibility'"
                @click:append="showPassword = !showPassword"
              >
              </v-text-field>
              <v-btn @click="registerAction" color="primary">Register</v-btn>
              <router-link :to="{ name: 'ResendConfirmation', params: { email: credentials.email }}">Didn't receive the instructions ?</router-link>
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

<script>
  import auth from '@/auth/index';
  import Gravatar from 'vue-gravatar';
  import RegisterAvatar from './RegisterAvatar';

  export default {
    props: {
      email: {
        type: String,
        required: false,
        default: '',
      },
      password: {
        type: String,
        required: false,
        default: '',
      },
    },
    components: {
      'v-gravatar': Gravatar,
      'avatar': RegisterAvatar
    },
    mounted() {
      this.credentials.email = this.email;
      this.credentials.password = this.password;
    },
    data() {
      return {
        credentials: {
          username: '',
          email: '',
          password: '',
        },
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
      registerAction(e) {
        this.resetState();
        e.preventDefault();
        auth.signup(JSON.stringify(this.credentials), (data) => {
          console.log(data);
          this.validationSent = true;
        }, (error) => {
          Promise.resolve(error).then((errormsg) => {
            console.log(errormsg);
            this.error.show = true;
            Object.entries(errormsg.errors.user).forEach(([key, val]) => {
              console.log(key);
              console.log(val);
              this.state[key] = { status: true, msg: val };
            });
          });
        });
      },
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
        return this.rules.email(this.credentials.email) === true ? 'v-gravatar' : 'avatar';
      }
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
