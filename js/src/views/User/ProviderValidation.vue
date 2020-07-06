<template> </template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { VALIDATE_USER, UPDATE_CURRENT_USER_CLIENT, LOGGED_USER } from "../../graphql/user";
import RouteName from "../../router/name";
import { saveUserData, changeIdentity } from "../../utils/auth";
import { ILogin } from "../../types/login.model";
import { ICurrentUserRole, ICurrentUser, IUser } from "../../types/current-user.model";
import { IDENTITIES } from "../../graphql/actor";

@Component
export default class ProviderValidate extends Vue {
  async mounted() {
    const accessToken = this.getValueFromMeta("auth-access-token");
    const refreshToken = this.getValueFromMeta("auth-refresh-token");
    const userId = this.getValueFromMeta("auth-user-id");
    const userEmail = this.getValueFromMeta("auth-user-email");
    const userRole = this.getValueFromMeta("auth-user-role") as ICurrentUserRole;
    const userActorId = this.getValueFromMeta("auth-user-actor-id");

    if (!(userId && userEmail && userRole && accessToken && refreshToken)) {
      return this.$router.push("/");
    }
    const login = {
      user: { id: userId, email: userEmail, role: userRole, isLoggedIn: true },
      accessToken,
      refreshToken,
    };
    saveUserData(login);
    await this.$apollo.mutate({
      mutation: UPDATE_CURRENT_USER_CLIENT,
      variables: {
        id: userId,
        email: userEmail,
        isLoggedIn: true,
        role: ICurrentUserRole.USER,
      },
    });
    const { data } = await this.$apollo.query<{ loggedUser: IUser }>({
      query: LOGGED_USER,
    });
    const { loggedUser } = data;

    if (loggedUser.defaultActor) {
      await changeIdentity(this.$apollo.provider.defaultClient, loggedUser.defaultActor);
      await this.$router.push({ name: RouteName.HOME });
    } else {
      // If the user didn't register any profile yet, let's create one for them
      await this.$router.push({
        name: RouteName.REGISTER_PROFILE,
        params: { email: loggedUser.email, userAlreadyActivated: "true" },
      });
    }
  }

  getValueFromMeta(name: string) {
    const element = document.querySelector(`meta[name="${name}"]`);
    if (element && element.getAttribute("content")) {
      return element.getAttribute("content");
    }
    return null;
  }
}
</script>
