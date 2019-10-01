<template>
  <section class="container">
    <h1 class="title" v-if="loading">
      {{ $t('Your account is being validated') }}
    </h1>
    <div v-else>
      <div v-if="failed">
        <b-message :title="$t('Error while validating account')" type="is-danger">
          {{ $t('Either the account is already validated, either the validation token is incorrect.') }}
        </b-message>
      </div>
      <h1 class="title" v-else>
        {{ $t('Your account has been validated') }}
      </h1>
    </div>
  </section>
</template>

<script lang="ts">
import { VALIDATE_USER } from '@/graphql/user';
import { Component, Prop, Vue } from 'vue-property-decorator';
import { AUTH_USER_ID } from '@/constants';
import { RouteName } from '@/router';
import { UserRouteName } from '@/router/user';
import { saveTokenData } from '@/utils/auth';

@Component
export default class Validate extends Vue {
  @Prop({ type: String, required: true }) token!: string;

  loading = true;
  failed = false;

  async created() {
    await this.validateAction();
  }

  async validateAction() {
    try {
      const { data } = await this.$apollo.mutate({
        mutation: VALIDATE_USER,
        variables: {
          token: this.token,
        },
      });

      this.saveUserData(data);

      const user = data.validateUser.user;
      console.log(user);
      if (user.defaultActor) {
        this.$router.push({ name: RouteName.HOME });
      } else { // If the user didn't register any profile yet, let's create one for them
        this.$router.push({ name: UserRouteName.REGISTER_PROFILE, params: { email: user.email, userAlreadyActivated: 'true' } });
      }
    } catch (err) {
      console.error(err);
      this.failed = true;
    } finally {
      this.loading = false;
    }
  }

  saveUserData({ validateUser: login }) {
    localStorage.setItem(AUTH_USER_ID, login.user.id);

    saveTokenData(login);
  }
}
</script>
