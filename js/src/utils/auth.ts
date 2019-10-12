import {
  AUTH_ACCESS_TOKEN,
  AUTH_REFRESH_TOKEN,
  AUTH_USER_ACTOR_ID,
  AUTH_USER_EMAIL,
  AUTH_USER_ID,
  AUTH_USER_ROLE,
} from '@/constants';
import { ILogin, IToken } from '@/types/login.model';
import { UPDATE_CURRENT_USER_CLIENT } from '@/graphql/user';
import { onLogout } from '@/vue-apollo';
import ApolloClient from 'apollo-client';
import { ICurrentUserRole } from '@/types/current-user.model';
import { IPerson } from '@/types/actor';
import { IDENTITIES, UPDATE_CURRENT_ACTOR_CLIENT } from '@/graphql/actor';

export function saveUserData(obj: ILogin) {
  localStorage.setItem(AUTH_USER_ID, `${obj.user.id}`);
  localStorage.setItem(AUTH_USER_EMAIL, obj.user.email);
  localStorage.setItem(AUTH_USER_ROLE, obj.user.role);

  saveTokenData(obj);
}

export function saveActorData(obj: IPerson) {
  localStorage.setItem(AUTH_USER_ACTOR_ID, `${obj.id}`);
}

export function saveTokenData(obj: IToken) {
  localStorage.setItem(AUTH_ACCESS_TOKEN, obj.accessToken);
  localStorage.setItem(AUTH_REFRESH_TOKEN, obj.refreshToken);
}

export function deleteUserData() {
  for (const key of [AUTH_USER_ID, AUTH_USER_EMAIL, AUTH_ACCESS_TOKEN, AUTH_REFRESH_TOKEN, AUTH_USER_ROLE]) {
    localStorage.removeItem(key);
  }
}

export class NoIdentitiesException extends Error {}

/**
 * We fetch from localStorage the latest actor ID used,
 * then fetch the current identities to set in cache
 * the current identity used
 */
export async function initializeCurrentActor(apollo: ApolloClient<any>) {
  const actorId = localStorage.getItem(AUTH_USER_ACTOR_ID);

  const result = await apollo.query({
    query: IDENTITIES,
    fetchPolicy: 'network-only',
  });
  const identities = result.data.identities;
  if (identities.length < 1) {
    console.warn('Logged user has no identities!');
    throw new NoIdentitiesException;
  }
  const activeIdentity = identities.find(identity => identity.id === actorId) || identities[0] as IPerson;

  if (activeIdentity) {
    return await changeIdentity(apollo, activeIdentity);
  }
}

export async function changeIdentity(apollo: ApolloClient<any>, identity: IPerson) {
  await apollo.mutate({
    mutation: UPDATE_CURRENT_ACTOR_CLIENT,
    variables: identity,
  });
  saveActorData(identity);
}

export async function logout(apollo: ApolloClient<any>) {
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

  await onLogout();
}
