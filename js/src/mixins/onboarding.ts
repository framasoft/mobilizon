import { SET_USER_SETTINGS, USER_SETTINGS } from "@/graphql/user";
import RouteName from "@/router/name";
import { ICurrentUser } from "@/types/current-user.model";
import { Component, Vue } from "vue-property-decorator";

@Component({
  apollo: {
    loggedUser: USER_SETTINGS,
  },
})
export default class Onboarding extends Vue {
  loggedUser!: ICurrentUser;

  RouteName = RouteName;

  protected async doUpdateSetting(
    variables: Record<string, unknown>
  ): Promise<void> {
    await this.$apollo.mutate<{ setUserSettings: string }>({
      mutation: SET_USER_SETTINGS,
      variables,
    });
  }
}
