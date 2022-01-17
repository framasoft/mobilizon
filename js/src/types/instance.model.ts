import { InstanceFollowStatus } from "./enums";

export interface IInstance {
  domain: string;
  hasRelay: boolean;
  followerStatus: InstanceFollowStatus;
  followedStatus: InstanceFollowStatus;
  personCount: number;
  groupCount: number;
  followersCount: number;
  followingsCount: number;
  reportsCount: number;
  mediaSize: number;
}
