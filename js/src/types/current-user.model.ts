export enum ICurrentUserRole {
  USER = 'USER',
  MODERATOR = 'MODERATOR',
  ADMINISTRATOR = 'ADMINISTRATOR',
}

export interface ICurrentUser {
  id: number;
  email: string;
  isLoggedIn: boolean;
  role: ICurrentUserRole;
}
