export interface IApplication {
  name: string;
  clientId: string;
  clientSecret?: string;
  redirectUris?: string;
  scope: string | null;
  website: string | null;
}

export interface IApplicationToken {
  id: string;
  application: IApplication;
  lastUsedAt: string;
  insertedAt: string;
}
