import {
  AUTH_ACCESS_TOKEN,
  AUTH_REFRESH_TOKEN,
  AUTH_USER_ACTOR_ID,
  AUTH_USER_EMAIL,
  AUTH_USER_ID,
  AUTH_USER_ROLE,
  USER_LOCALE,
} from "@/constants";
import { ILogin, IToken } from "@/types/login.model";
import { UPDATE_CURRENT_USER_CLIENT } from "@/graphql/user";
import { UPDATE_CURRENT_ACTOR_CLIENT } from "@/graphql/actor";
import { ICurrentUserRole } from "@/types/enums";
import { LOGOUT } from "@/graphql/auth";
import { provideApolloClient, useMutation } from "@vue/apollo-composable";
import { apolloClient } from "@/vue-apollo";

export function saveTokenData(obj: IToken): void {
  localStorage.setItem(AUTH_ACCESS_TOKEN, obj.accessToken);
  localStorage.setItem(AUTH_REFRESH_TOKEN, obj.refreshToken);
}

export function saveUserData(obj: ILogin): void {
  localStorage.setItem(AUTH_USER_ID, `${obj.user.id}`);
  localStorage.setItem(AUTH_USER_EMAIL, obj.user.email);
  localStorage.setItem(AUTH_USER_ROLE, obj.user.role);

  saveTokenData(obj);
}

export function saveLocaleData(locale: string): void {
  localStorage.setItem(USER_LOCALE, locale);
}

export function getLocaleData(): string | null {
  return localStorage ? localStorage.getItem(USER_LOCALE) : null;
}

export function deleteUserData(): void {
  [
    AUTH_USER_ID,
    AUTH_USER_EMAIL,
    AUTH_ACCESS_TOKEN,
    AUTH_REFRESH_TOKEN,
    AUTH_USER_ACTOR_ID,
    AUTH_USER_ROLE,
  ].forEach((key) => {
    localStorage.removeItem(key);
  });
}

const { mutate: logoutMutation } = provideApolloClient(apolloClient)(() =>
  useMutation(LOGOUT)
);
const { mutate: cleanUserClient } = provideApolloClient(apolloClient)(() =>
  useMutation(UPDATE_CURRENT_USER_CLIENT)
);
const { mutate: cleanActorClient } = provideApolloClient(apolloClient)(() =>
  useMutation(UPDATE_CURRENT_ACTOR_CLIENT)
);

export async function logout(performServerLogout = true): Promise<void> {
  if (performServerLogout) {
    logoutMutation({
      refreshToken: localStorage.getItem(AUTH_REFRESH_TOKEN),
    });
  }

  cleanUserClient({
    id: null,
    email: null,
    isLoggedIn: false,
    role: ICurrentUserRole.USER,
  });

  cleanActorClient({
    id: null,
    avatar: null,
    preferredUsername: null,
    name: null,
  });

  deleteUserData();
}

export const SELECTED_PROVIDERS: { [key: string]: string } = {
  twitter: "Twitter",
  discord: "Discord",
  facebook: "Facebook",
  github: "Github",
  gitlab: "Gitlab",
  google: "Google",
  keycloak: "Keycloak",
  ldap: "LDAP",
  cas: "CAS",
};
