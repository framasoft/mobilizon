import { IPicture } from '@/types/picture.model';

export interface IActor {
  id?: number;
  url: string;
  name: string;
  domain: string|null;
  summary: string;
  preferredUsername: string;
  suspended: boolean;
  avatar: IPicture | null;
  banner: IPicture | null;

  displayName();
}

export class Actor implements IActor {
  id?: number;
  avatar: IPicture | null = null;
  banner: IPicture | null = null;
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

  public displayName(): string {
    return this.name != null && this.name !== '' ? this.name : this.usernameWithDomain();
  }
}
