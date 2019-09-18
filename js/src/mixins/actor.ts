import { IActor } from '@/types/actor';
import { IEvent } from '@/types/event.model';
import { Component, Vue } from 'vue-property-decorator';

@Component
export default class ActorMixin extends Vue {
  actorIsOrganizer(actor: IActor, event: IEvent) {
    console.log('actorIsOrganizer actor', actor.id);
    console.log('actorIsOrganizer event', event);
    return event.organizerActor && actor.id === event.organizerActor.id;
  }
}
