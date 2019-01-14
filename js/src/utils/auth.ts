import { AUTH_TOKEN, AUTH_USER_ID } from '@/constants';
import { ILogin } from '@/types/login.model';

export function saveUserData(obj: ILogin) {
  localStorage.setItem(AUTH_USER_ID, `${obj.user.id}`);
  localStorage.setItem(AUTH_TOKEN, obj.token);
}
