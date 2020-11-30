<template>
  <section class="section container">
    <h1 class="title" v-if="loading">
      {{ $t("Your account is being validated") }}
    </h1>
    <div v-else>
      <div v-if="failed">
        <b-message
          :title="$t('Error while validating account')"
          type="is-danger"
        >
          {{
            $t(
              "Either the account is already validated, either the validation token is incorrect."
            )
          }}
        </b-message>
      </div>
      <h1 class="title" v-else>{{ $t("Your account has been validated") }}</h1>
    </div>
  </section>
</template>

<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { ICurrentUserRole } from "@/types/enums";
import { VALIDATE_USER, UPDATE_CURRENT_USER_CLIENT } from "../../graphql/user";
import RouteName from "../../router/name";
import { saveUserData, saveTokenData, changeIdentity } from "../../utils/auth";
import { ILogin } from "../../types/login.model";

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
      const { data } = await this.$apollo.mutate<{ validateUser: ILogin }>({
        mutation: VALIDATE_USER,
        variables: {
          token: this.token,
        },
      });

      if (data) {
        saveUserData(data.validateUser);
        saveTokenData(data.validateUser);

        const { user } = data.validateUser;

        await this.$apollo.mutate({
          mutation: UPDATE_CURRENT_USER_CLIENT,
          variables: {
            id: user.id,
            email: user.email,
            isLoggedIn: true,
            role: ICurrentUserRole.USER,
          },
        });

        if (user.defaultActor) {
          await changeIdentity(
            this.$apollo.provider.defaultClient,
            user.defaultActor
          );
          await this.$router.push({ name: RouteName.HOME });
        } else {
          // If the user didn't register any profile yet, let's create one for them
          await this.$router.push({
            name: RouteName.REGISTER_PROFILE,
            params: { email: user.email, userAlreadyActivated: "true" },
          });
        }
      }
    } catch (err) {
      console.error(err);
      this.failed = true;
    } finally {
      this.loading = false;
    }
  }
}
</script>
