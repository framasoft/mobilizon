import { IActor } from "./actor.model";

export enum EventStatus {
    TENTATIVE,
    CONFIRMED,
    CANCELLED
}

export enum EventVisibility {
    PUBLIC,
    UNLISTED,
    RESTRICTED,
    PRIVATE
}

export enum EventJoinOptions {
    FREE,
    RESTRICTED,
    INVITE
}

export enum ParticipantRole {

}

export interface ICategory {
    title: string;
    description: string;
    picture: string;
}

export interface IParticipant {
    role: ParticipantRole,
    actor: IActor,
    event: IEvent
}

export interface IEvent {
    uuid: string;
    url: string;
    local: boolean;
    title: string;
    description: string;
    begins_on: Date;
    ends_on: Date;
    status: EventStatus;
    visibility: EventVisibility;
    join_options: EventJoinOptions;
    thumbnail: string;
    large_image: string;
    publish_at: Date;
    // online_address: Adress;
    // phone_address: string;
    organizerActor: IActor;
    attributedTo: IActor;
    participants: IParticipant[];
    category: ICategory;
}