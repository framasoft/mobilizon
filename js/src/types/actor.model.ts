export interface IActor {
    id: string;
    url: string;
    name: string;
    domain: string|null;
    summary: string;
    preferredUsername: string;
    suspended: boolean;
    avatarUrl: string;
    bannerUrl: string;
}

export interface IPerson extends IActor {

}

export interface IGroup extends IActor {
    members: IMember[];
}

export enum MemberRole {
    PENDING, MEMBER, MODERATOR, ADMIN
}

export interface IMember {
    role: MemberRole;
    parent: IGroup;
    actor: IActor;
}