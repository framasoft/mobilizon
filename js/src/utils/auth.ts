import { AUTH_TOKEN, AUTH_USER_EMAIL, AUTH_USER_ID } from '@/constants';
import { ILogin } from '@/types/login.model';

export function saveUserData(obj: ILogin) {
  localStorage.setItem(AUTH_USER_ID, `${obj.user.id}`);
  localStorage.setItem(AUTH_USER_EMAIL, obj.user.email);
  localStorage.setItem(AUTH_TOKEN, obj.token);
}

export function deleteUserData() {
  for (const key of [AUTH_USER_ID, AUTH_USER_EMAIL, AUTH_TOKEN]) {
    localStorage.removeItem(key);
  }
}
