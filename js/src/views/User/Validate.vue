<template>
  <section>
    <h1 class="title" v-if="loading">
      <translate>Your account is being validated</translate>
    </h1>
    <div v-else>
      <div v-if="failed">
        <b-message title="Error" type="is-danger">
          <translate>Error while validating account</translate>
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

@Component
export default class Validate extends Vue {
  @Prop({ type: String, required: true }) token!: string;

  loading = true;
  failed = false;

  created() {
    this.validateAction();
  }

  async validateAction() {
    try {
      const data = await this.$apollo.mutate({
        mutation: VALIDATE_USER,
        variables: {
          token: this.token
        }
      });

      this.saveUserData(data.data);
      this.$router.push({ name: "Home" });
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
