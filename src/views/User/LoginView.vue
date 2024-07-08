<template>
  <section
    class="container mx-auto max-w-screen-sm"
    v-if="!currentUser?.isLoggedIn"
  >
    <h1 class="text-4xl">{{ t("Welcome back!") }}</h1>
    <o-notification
      v-if="errorCode === LoginErrorCode.NEED_TO_LOGIN"
      title="Info"
      variant="info"
      :aria-close-label="t('Close')"
      >{{ t("You need to login.") }}</o-notification
    >
    <o-notification
      v-else-if="errorCode === LoginError.LOGIN_PROVIDER_ERROR"
      variant="danger"
      :aria-close-label="t('Close')"
      >{{
        t("Error while login with {provider}. Retry or login another way.", {
          provider: currentProvider,
        })
      }}</o-notification
    >
    <o-notification
      v-else-if="errorCode === LoginError.LOGIN_PROVIDER_NOT_FOUND"
      variant="danger"
      :aria-close-label="t('Close')"
      >{{
        t(
          "Error while login with {provider}. This login provider doesn't exist.",
          {
            provider: currentProvider,
          }
        )
      }}</o-notification
    >
    <o-notification
      :title="t('Error')"
      variant="danger"
      v-for="error in errors"
      :key="error"
    >
      {{ error }}
    </o-notification>
    <form @submit="loginAction" v-if="config?.auth?.databaseLogin">
      <o-field
        :label="t('Email')"
        label-for="email"
        :message="caseWarningText"
        :type="caseWarningType"
      >
        <o-input
          aria-required="true"
          required
          expanded
          id="email"
          type="email"
          v-model="credentials.email"
        />
      </o-field>

      <o-field :label="t('Password')" label-for="password">
        <o-input
          aria-required="true"
          id="password"
          required
          expanded
          type="password"
          password-reveal
          v-model="credentials.password"
        />
      </o-field>

      <p class="text-center my-2">
        <o-button
          variant="primary"
          size="large"
          native-type="submit"
          :disabled="submitted"
        >
          {{ t("Login") }}
        </o-button>
      </p>
      <!-- <o-loading :is-full-page="false" v-model="submitted" /> -->

      <div class="flex flex-wrap gap-2 mt-3">
        <o-button
          tag="router-link"
          variant="text"
          :to="{
            name: RouteName.SEND_PASSWORD_RESET,
            params: { email: credentials.email },
          }"
          >{{ t("Forgot your password?") }}</o-button
        >
        <o-button
          tag="router-link"
          variant="text"
          :to="{
            name: RouteName.RESEND_CONFIRMATION,
            params: { email: credentials.email },
          }"
          >{{ t("Didn't receive the instructions?") }}</o-button
        >
        <p class="control" v-if="canRegister">
          <o-button
            tag="router-link"
            variant="text"
            :to="{
              name: RouteName.REGISTER,
              query: {
                default_email: credentials.email,
                default_password: credentials.password,
              },
            }"
            >{{ t("Create an account") }}</o-button
          >
        </p>
      </div>
    </form>
    <div v-if="config && config?.auth?.oauthProviders?.length > 0">
      <auth-providers :oauthProviders="config.auth.oauthProviders" />
    </div>
  </section>
</template>

<script setup lang="ts">
import { LOGIN } from "@/graphql/auth";
import { LOGIN_CONFIG } from "@/graphql/config";
import { LOGGED_USER_LOCATION } from "@/graphql/user";
import { UPDATE_CURRENT_USER_CLIENT } from "@/graphql/user";
import { IConfig } from "@/types/config.model";
import { IUser } from "@/types/current-user.model";
import { saveUserData, SELECTED_PROVIDERS } from "@/utils/auth";
import { storeUserLocationAndRadiusFromUserSettings } from "@/utils/location";
import {
  initializeCurrentActor,
  NoIdentitiesException,
} from "@/utils/identity";
import { useMutation, useLazyQuery, useQuery } from "@vue/apollo-composable";
import { computed, reactive, ref, onMounted } from "vue";
import { useI18n } from "vue-i18n";
import { useRoute, useRouter } from "vue-router";
import AuthProviders from "@/components/User/AuthProviders.vue";
import RouteName from "@/router/name";
import { LoginError, LoginErrorCode } from "@/types/enums";
import { useCurrentUserClient } from "@/composition/apollo/user";
import { useHead } from "@/utils/head";
import { enumTransformer, useRouteQuery } from "vue-use-route-query";
import { useLazyCurrentUserIdentities } from "@/composition/apollo/actor";

const { t } = useI18n({ useScope: "global" });
const router = useRouter();
const route = useRoute();

const { currentUser } = useCurrentUserClient();

const configQuery = useQuery<{
  config: Pick<
    IConfig,
    "auth" | "registrationsOpen" | "registrationsAllowlist"
  >;
}>(LOGIN_CONFIG);

const config = computed(() => configQuery.result.value?.config);

const canRegister = computed(() => {
  return (
    (config.value?.registrationsOpen || config.value?.registrationsAllowlist) &&
    config.value?.auth?.databaseLogin
  );
});

const errors = ref<string[]>([]);
const submitted = ref(false);

const credentials = reactive({
  email: typeof route.query.email === "string" ? route.query.email : "",
  password:
    typeof route.query.password === "string" ? route.query.password : "",
});

const redirect = useRouteQuery("redirect", "");
const errorCode = useRouteQuery("code", null, enumTransformer(LoginErrorCode));

// Login
const loginMutation = useMutation(LOGIN);
// Load user identities
const currentUserIdentitiesQuery = useLazyCurrentUserIdentities();
// Update user in cache
const currentUserMutation = useMutation(UPDATE_CURRENT_USER_CLIENT);
// Retrieve preferred location
const loggedUserLocationQuery = useLazyQuery<{
  loggedUser: IUser;
}>(LOGGED_USER_LOCATION);

// form submit action
const loginAction = async (e: Event) => {
  e.preventDefault();
  if (submitted.value) {
    return;
  }
  submitted.value = true;
  errors.value = [];

  try {
    // Step 1: login the user
    const { data: loginData } = await loginMutation.mutate({
      email: credentials.email,
      password: credentials.password,
    });
    submitted.value = false;
    if (loginData == null) {
      throw new Error("Login: user's data is undefined");
    }

    // Login saved to local storage
    saveUserData(loginData.login);

    // Step 2: save login in apollo cache
    await currentUserMutation.mutate({
      id: loginData.login.user.id,
      email: credentials.email,
      isLoggedIn: true,
      role: loginData.login.user.role,
    });

    // Step 3a: Retrieving user location
    const loggedUserLocationPromise = loggedUserLocationQuery.load();

    // Step 3b: Setuping user's identities
    // FIXME this promise never resolved the first time
    // no idea why !
    // this appends even with the last version of apollo-composable (4.0.2)
    // may be related to that : https://github.com/vuejs/apollo/issues/1543
    // EDIT: now it works :shrug:
    const currentUserIdentitiesResult = await currentUserIdentitiesQuery.load();
    if (!currentUserIdentitiesResult) {
      throw new Error("Loading user's identities failed");
    }

    await initializeCurrentActor(currentUserIdentitiesResult.loggedUser.actors);

    // Step 3a following
    const loggedUserLocationResult = await loggedUserLocationPromise;
    storeUserLocationAndRadiusFromUserSettings(
      loggedUserLocationResult?.loggedUser?.settings?.location
    );

    // Soft redirect
    if (redirect.value) {
      console.debug("We have a redirect", redirect.value);
      router.push(redirect.value);
      return;
    }
    console.debug("No redirect, going to homepage");
    if (window.localStorage) {
      console.debug("Has localstorage, setting welcome back");
      window.localStorage.setItem("welcome-back", "yes");
    }
    router.replace({ name: RouteName.HOME });

    // Hard redirect
    // since we fail to refresh the navbar properly, we force a page reload.
    // see the explanation of the bug bellow
    // window.location = redirect.value || "/";
  } catch (err: any) {
    if (err instanceof NoIdentitiesException && currentUser.value) {
      console.debug("No identities, redirecting to profile registration");
      await router.push({
        name: RouteName.REGISTER_PROFILE,
        params: {
          email: currentUser.value.email,
          userAlreadyActivated: "true",
        },
      });
    } else {
      console.error(err);
      submitted.value = false;
      if (err.graphQLErrors) {
        err.graphQLErrors.forEach(({ message }: { message: string }) => {
          errors.value.push(message);
        });
      } else if (err.networkError) {
        errors.value.push(err.networkError.message);
      }
    }
  }
};

const hasCaseWarning = computed<boolean>(() => {
  return credentials.email !== credentials.email.toLowerCase();
});

const caseWarningText = computed<string | undefined>(() => {
  if (hasCaseWarning.value) {
    return t(
      "Emails usually don't contain capitals, make sure you haven't made a typo."
    ) as string;
  }
  return undefined;
});

const caseWarningType = computed<string | undefined>(() => {
  if (hasCaseWarning.value) {
    return "warning";
  }
  return undefined;
});

const currentProvider = computed(() => {
  const queryProvider = route?.query.provider as string | undefined;
  if (queryProvider) {
    return SELECTED_PROVIDERS[queryProvider];
  }
  return "unknown provider";
});

onMounted(() => {
  // Already-logged-in and accessing /login
  if (currentUser.value?.isLoggedIn) {
    console.debug(
      "Current user is already logged-in, redirecting to Homepage",
      currentUser.value
    );
    router.push("/");
  }
});

useHead({
  title: computed(() => t("Login")),
});
</script>
