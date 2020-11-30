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
import ApolloClient from "apollo-client";
import { IPerson } from "@/types/actor";
import { IDENTITIES, UPDATE_CURRENT_ACTOR_CLIENT } from "@/graphql/actor";
import { NormalizedCacheObject } from "apollo-cache-inmemory";
import { ICurrentUserRole } from "@/types/enums";

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
  return localStorage.getItem(USER_LOCALE);
}

export function saveActorData(obj: IPerson): void {
  localStorage.setItem(AUTH_USER_ACTOR_ID, `${obj.id}`);
}

export function deleteUserData(): void {
  [
    AUTH_USER_ID,
    AUTH_USER_EMAIL,
    AUTH_ACCESS_TOKEN,
    AUTH_REFRESH_TOKEN,
    AUTH_USER_ROLE,
  ].forEach((key) => {
    localStorage.removeItem(key);
  });
}

export class NoIdentitiesException extends Error {}

export async function changeIdentity(
  apollo: ApolloClient<NormalizedCacheObject>,
  identity: IPerson
): Promise<void> {
  await apollo.mutate({
    mutation: UPDATE_CURRENT_ACTOR_CLIENT,
    variables: identity,
  });
  saveActorData(identity);
}

/**
 * We fetch from localStorage the latest actor ID used,
 * then fetch the current identities to set in cache
 * the current identity used
 */
export async function initializeCurrentActor(
  apollo: ApolloClient<any>
): Promise<void> {
  const actorId = localStorage.getItem(AUTH_USER_ACTOR_ID);

  const result = await apollo.query({
    query: IDENTITIES,
    fetchPolicy: "network-only",
  });
  const { identities } = result.data;
  if (identities.length < 1) {
    console.warn("Logged user has no identities!");
    throw new NoIdentitiesException();
  }
  const activeIdentity =
    identities.find((identity: IPerson) => identity.id === actorId) ||
    (identities[0] as IPerson);

  if (activeIdentity) {
    await changeIdentity(apollo, activeIdentity);
  }
}

export async function logout(
  apollo: ApolloClient<NormalizedCacheObject>
): Promise<void> {
  await apollo.mutate({
    mutation: UPDATE_CURRENT_USER_CLIENT,
    variables: {
      id: null,
      email: null,
      isLoggedIn: false,
      role: ICurrentUserRole.USER,
    },
  });

  await apollo.mutate({
    mutation: UPDATE_CURRENT_ACTOR_CLIENT,
    variables: {
      id: null,
      avatar: null,
      preferredUsername: null,
      name: null,
    },
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
};
