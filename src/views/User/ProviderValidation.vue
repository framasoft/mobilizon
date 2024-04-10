<template>
  <p>{{ t("Redirecting in progress…") }}</p>
</template>

<script lang="ts" setup>
import { ICurrentUserRole } from "@/types/enums";
import { UPDATE_CURRENT_USER_CLIENT, LOGGED_USER } from "../../graphql/user";
import RouteName from "../../router/name";
import { saveUserData } from "../../utils/auth";
import { changeIdentity } from "../../utils/identity";
import { ICurrentUser, IUser } from "../../types/current-user.model";
import { useRouter } from "vue-router";
import { useLazyQuery, useMutation } from "@vue/apollo-composable";
import { useI18n } from "vue-i18n";
import { useHead } from "@/utils/head";
import { computed, onMounted } from "vue";
import { getValueFromMeta } from "@/utils/html";

const { t } = useI18n({ useScope: "global" });
useHead({
  title: computed(() => t("Redirecting to Mobilizon")),
});

const accessToken = getValueFromMeta("auth-access-token");
const refreshToken = getValueFromMeta("auth-refresh-token");
const userId = getValueFromMeta("auth-user-id");
const userEmail = getValueFromMeta("auth-user-email");
const userRole = getValueFromMeta("auth-user-role") as ICurrentUserRole;

const router = useRouter();

const {
  onDone: onUpdateCurrentUserClientDone,
  mutate: updateCurrentUserClient,
} = useMutation<
  { updateCurrentUser: ICurrentUser },
  { id: string; email: string; isLoggedIn: boolean; role: ICurrentUserRole }
>(UPDATE_CURRENT_USER_CLIENT);

const { load: loadUser } = useLazyQuery<{
  loggedUser: IUser;
}>(LOGGED_USER);

onUpdateCurrentUserClientDone(async () => {
  try {
    const result = await loadUser();
    if (!result) return;
    const loggedUser = result.loggedUser;
    if (loggedUser.defaultActor) {
      await changeIdentity(loggedUser.defaultActor);
      await router.push({ name: RouteName.HOME });
    } else {
      // No need to push to REGISTER_PROFILE, the navbar will do it for us
    }
  } catch (e) {
    console.error(e);
  }
});

onMounted(async () => {
  if (!(userId && userEmail && userRole && accessToken && refreshToken)) {
    await router.push("/");
  } else {
    const login = {
      user: {
        id: userId,
        email: userEmail,
        role: userRole,
        isLoggedIn: true,
        defaultActor: undefined,
        actors: [],
      },
      accessToken,
      refreshToken,
    };
    saveUserData(login);

    updateCurrentUserClient({
      id: userId,
      email: userEmail,
      isLoggedIn: true,
      role: userRole,
    });
  }
});
</script>
