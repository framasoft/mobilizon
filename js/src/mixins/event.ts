import { mixins } from 'vue-class-component';
import { Component, Vue } from 'vue-property-decorator';
import { IEvent, IParticipant } from '@/types/event.model';
import { DELETE_EVENT } from '@/graphql/event';
import { RouteName } from '@/router';
import { IPerson } from '@/types/actor';

@Component
export default class EventMixin extends mixins(Vue) {
  async openDeleteEventModal (event: IEvent, currentActor: IPerson) {
    const participantsLength = event.participantStats.participant;
    const prefix = participantsLength
            ? this.$tc('There are {participants} participants.', event.participantStats.participant, {
              participants: event.participantStats.participant,
            })
            : '';

    this.$buefy.dialog.prompt({
      type: 'is-danger',
      title: this.$t('Delete event') as string,
      message: `${prefix}
        ${this.$t('Are you sure you want to delete this event? This action cannot be reverted.')}
        <br><br>
        ${this.$t('To confirm, type your event title "{eventTitle}"', { eventTitle: event.title })}`,
      confirmText: this.$t(
                'Delete {eventTitle}',
                { eventTitle: event.title },
            ) as string,
      inputAttrs: {
        placeholder: event.title,
        pattern: event.title,
      },
      onConfirm: () => this.deleteEvent(event, currentActor),
    });
  }

  private async deleteEvent(event: IEvent, currentActor: IPerson) {
    const eventTitle = event.title;

    try {
      await this.$apollo.mutate<IParticipant>({
        mutation: DELETE_EVENT,
        variables: {
          eventId: event.id,
          actorId: currentActor.id,
        },
      });
      /**
       * When the event corresponding has been deleted (by the organizer). A notification is already triggered.
       *
       * @type {string}
       */
      this.$emit('eventDeleted', event.id);

      this.$buefy.notification.open({
        message: this.$t('Event {eventTitle} deleted', { eventTitle }) as string,
        type: 'is-success',
        position: 'is-bottom-right',
        duration: 5000,
      });
      await this.$router.push({ name: RouteName.HOME });
    } catch (error) {
      console.error(error);
    }
  }
}
