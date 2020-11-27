import type { IActor } from "@/types/actor/actor.model";

export interface IFollower {
  id?: string;
  actor: IActor;
  targetActor: IActor;
  approved: boolean;
}
