import { ICurrentUser } from '@/types/current-user.model';

export interface ILogin {
  user: ICurrentUser,

  token: string,
}
