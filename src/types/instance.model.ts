import { InstanceFollowStatus } from "./enums";

export interface IInstance {
  domain: string;
  hasRelay: boolean;
  instanceName: string | null;
  instanceDescription: string | null;
  software: string | null;
  softwareVersion: string | null;
  relayAddress: string | null;
  followerStatus: InstanceFollowStatus;
  followedStatus: InstanceFollowStatus;
  personCount: number;
  groupCount: number;
  followersCount: number;
  followingsCount: number;
  reportsCount: number;
  mediaSize: number;
  eventCount: number;
}
