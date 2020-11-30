<script lang="ts">
import { Component, Vue } from "vue-property-decorator";
import { ICurrentUserRole } from "@/types/enums";
import { UPDATE_CURRENT_USER_CLIENT, LOGGED_USER } from "../../graphql/user";
import RouteName from "../../router/name";
import { saveUserData, changeIdentity } from "../../utils/auth";
import { IUser } from "../../types/current-user.model";

@Component
export default class ProviderValidate extends Vue {
  async mounted(): Promise<void> {
    const accessToken = this.getValueFromMeta("auth-access-token");
    const refreshToken = this.getValueFromMeta("auth-refresh-token");
    const userId = this.getValueFromMeta("auth-user-id");
    const userEmail = this.getValueFromMeta("auth-user-email");
    const userRole = this.getValueFromMeta(
      "auth-user-role"
    ) as ICurrentUserRole;

    if (!(userId && userEmail && userRole && accessToken && refreshToken)) {
      await this.$router.push("/");
    } else {
      const login = {
        user: {
          id: userId,
          email: userEmail,
          role: userRole,
          isLoggedIn: true,
        },
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
        await changeIdentity(
          this.$apollo.provider.defaultClient,
          loggedUser.defaultActor
        );
        await this.$router.push({ name: RouteName.HOME });
      } else {
        // If the user didn't register any profile yet, let's create one for them
        await this.$router.push({
          name: RouteName.REGISTER_PROFILE,
          params: { email: loggedUser.email, userAlreadyActivated: "true" },
        });
      }
    }
  }

  // eslint-disable-next-line class-methods-use-this
  getValueFromMeta(name: string): string | null {
    const element = document.querySelector(`meta[name="${name}"]`);
    if (element && element.getAttribute("content")) {
      return element.getAttribute("content");
    }
    return null;
  }
}
</script>
