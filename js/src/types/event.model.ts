import { IActor } from "./actor.model";

export enum EventStatus {
    TENTATIVE, CONFIRMED, CANCELLED
}

export enum EventVisibility {
    PUBLIC, PRIVATE
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