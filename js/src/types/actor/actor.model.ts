export interface IActor {
  id?: string;
  url: string;
  name: string;
  domain: string|null;
  summary: string;
  preferredUsername: string;
  suspended: boolean;
  avatarUrl: string;
  bannerUrl: string;
}

export class Actor implements IActor {
  avatarUrl: string = '';
  bannerUrl: string = '';
  domain: string | null = null;
  name: string = '';
  preferredUsername: string = '';
  summary: string = '';
  suspended: boolean = false;
  url: string = '';

  constructor (hash: IActor | {} = {}) {
    Object.assign(this, hash);
  }

  get displayNameAndUsername(): string {
    return `${this.name} (${this.usernameWithDomain})`;
  }

  usernameWithDomain(): string {
    const domain = this.domain ? `@${this.domain}` : '';
    return `@${this.preferredUsername}${domain}`;
  }

  displayName(): string {
    return this.name != null && this.name !== '' ? this.name : this.usernameWithDomain();
  }
}
