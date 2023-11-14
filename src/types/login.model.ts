import type { ICurrentUser } from "@/types/current-user.model";

export interface IToken {
  accessToken: string;
  refreshToken: string;
}

export interface ILogin extends IToken {
  user: ICurrentUser;
}
