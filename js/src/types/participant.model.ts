import { Actor, IActor } from "./actor";
import { EventModel, IEvent } from "./event.model";

export enum ParticipantRole {
  NOT_APPROVED = "NOT_APPROVED",
  NOT_CONFIRMED = "NOT_CONFIRMED",
  REJECTED = "REJECTED",
  PARTICIPANT = "PARTICIPANT",
  MODERATOR = "MODERATOR",
  ADMINISTRATOR = "ADMINISTRATOR",
  CREATOR = "CREATOR",
}

export interface IParticipant {
  id?: string;
  role: ParticipantRole;
  actor: IActor;
  event: IEvent;
  metadata: { cancellationToken?: string; message?: string };
  insertedAt?: Date;
}

export class Participant implements IParticipant {
  id?: string;

  event!: IEvent;

  actor!: IActor;

  role: ParticipantRole = ParticipantRole.NOT_APPROVED;

  metadata = {};

  insertedAt?: Date;

  constructor(hash?: IParticipant) {
    if (!hash) return;

    this.id = hash.id;
    this.event = new EventModel(hash.event);
    this.actor = new Actor(hash.actor);
    this.role = hash.role;
    this.metadata = hash.metadata;
    this.insertedAt = hash.insertedAt;
  }
}
