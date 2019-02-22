<template>
  <section>
    <h1 class="title" v-if="loading">
      <translate>Your account is being validated</translate>
    </h1>
    <div v-else>
      <div v-if="failed">
        <b-message :title="$gettext('Error while validating account')" type="is-danger">
          <translate>Either the account is already validated, either the validation token is incorrect.</translate>
        </b-message>
      </div>
      <h1 class="title" v-else>
        <translate>Your account has been validated</translate>
      </h1>
    </div>
  </section>
</template>

<script lang="ts">
import { VALIDATE_USER } from "@/graphql/user";
import { Component, Prop, Vue } from "vue-property-decorator";
import { AUTH_TOKEN, AUTH_USER_ID } from "@/constants";
import { RouteName } from '@/router'
import { UserRouteName } from '@/router/user'

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
          token: this.token
        }
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
    localStorage.setItem(AUTH_TOKEN, login.token);
  }
}
</script>
