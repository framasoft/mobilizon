<template>
  <section class="section container">
    <h1 class="title" v-if="loading">
      {{ $t("Your email is being changed") }}
    </h1>
    <div v-else>
      <div v-if="failed">
        <b-message :title="$t('Error while changing email')" type="is-danger">
          {{
            $t(
              "Either the email has already been changed, either the validation token is incorrect."
            )
          }}
        </b-message>
      </div>
      <h1 class="title" v-else>{{ $t("Your email has been changed") }}</h1>
    </div>
  </section>
</template>

<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { VALIDATE_EMAIL } from "../../graphql/user";
import RouteName from "../../router/name";
import { ICurrentUser } from "../../types/current-user.model";

@Component
export default class Validate extends Vue {
  @Prop({ type: String, required: true }) token!: string;

  loading = true;

  failed = false;

  async created(): Promise<void> {
    await this.validateAction();
  }

  async validateAction(): Promise<void> {
    try {
      await this.$apollo.mutate<{ validateEmail: ICurrentUser }>({
        mutation: VALIDATE_EMAIL,
        variables: {
          token: this.token,
        },
      });
      this.loading = false;
      await this.$router.push({ name: RouteName.HOME });
    } catch (err) {
      console.error(err);
      this.failed = true;
    }
  }
}
</script>
