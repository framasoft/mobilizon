import { IActor } from "@/types/actor";
import { IEvent } from "@/types/event.model";
import { Component, Vue } from "vue-property-decorator";

@Component
export default class ActorMixin extends Vue {
  static actorIsOrganizer(actor: IActor, event: IEvent): boolean {
    console.log("actorIsOrganizer actor", actor.id);
    console.log("actorIsOrganizer event", event);
    return (
      event.organizerActor !== undefined && actor.id === event.organizerActor.id
    );
  }
}
