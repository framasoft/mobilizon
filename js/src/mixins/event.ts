import { mixins } from "vue-class-component";
import { Component, Vue } from "vue-property-decorator";
import { IEvent, IParticipant, ParticipantRole } from "../types/event.model";
import {
  DELETE_EVENT,
  EVENT_PERSON_PARTICIPATION,
  FETCH_EVENT,
  LEAVE_EVENT,
} from "../graphql/event";
import RouteName from "../router/name";
import { IPerson } from "../types/actor";

@Component
export default class EventMixin extends mixins(Vue) {
  protected async leaveEvent(
    event: IEvent,
    actorId: string,
    token: string | null = null,
    anonymousParticipationConfirmed: boolean | null = null
  ) {
    try {
      const { data: resultData } = await this.$apollo.mutate<{ leaveEvent: IParticipant }>({
        mutation: LEAVE_EVENT,
        variables: {
          eventId: event.id,
          actorId,
          token,
        },
        update: (store, { data }) => {
          if (data == null) return;
          let participation;

          if (!token) {
            const participationCachedData = store.readQuery<{ person: IPerson }>({
              query: EVENT_PERSON_PARTICIPATION,
              variables: { eventId: event.id, actorId },
            });
            if (participationCachedData == null) return;
            const { person } = participationCachedData;
            if (person === null) {
              console.error("Cannot update participation cache, because of null value.");
              return;
            }
            [participation] = person.participations;
            person.participations = [];
            store.writeQuery({
              query: EVENT_PERSON_PARTICIPATION,
              variables: { eventId: event.id, actorId },
              data: { person },
            });
          }

          const eventCachedData = store.readQuery<{ event: IEvent }>({
            query: FETCH_EVENT,
            variables: { uuid: event.uuid },
          });
          if (eventCachedData == null) return;
          const { event: eventCached } = eventCachedData;
          if (eventCached === null) {
            console.error("Cannot update event cache, because of null value.");
            return;
          }
          if (participation && participation.role === ParticipantRole.NOT_APPROVED) {
            eventCached.participantStats.notApproved -= 1;
          } else if (anonymousParticipationConfirmed === false) {
            eventCached.participantStats.notConfirmed -= 1;
          } else {
            eventCached.participantStats.going -= 1;
            eventCached.participantStats.participant -= 1;
          }
          store.writeQuery({
            query: FETCH_EVENT,
            variables: { uuid: event.uuid },
            data: { event: eventCached },
          });
        },
      });
      if (resultData) {
        this.participationCancelledMessage();
      }
    } catch (error) {
      console.error(error);
    }
  }

  private participationCancelledMessage() {
    this.$notifier.success(this.$t("You have cancelled your participation") as string);
  }

  protected async openDeleteEventModal(event: IEvent, currentActor: IPerson) {
    function escapeRegExp(string: string) {
      return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'); // $& means the whole matched string
    }  	  
    const participantsLength = event.participantStats.participant;
    const prefix = participantsLength
      ? this.$tc("There are {participants} participants.", event.participantStats.participant, {
          participants: event.participantStats.participant,
        })
      : "";

    this.$buefy.dialog.prompt({
      type: "is-danger",
      title: this.$t("Delete event") as string,
      message: `${prefix}
        ${this.$t("Are you sure you want to delete this event? This action cannot be reverted.")}
        <br><br>
        ${this.$t('To confirm, type your event title "{eventTitle}"', {
          eventTitle: event.title,
        })}`,
      confirmText: this.$t("Delete {eventTitle}", { eventTitle: event.title }) as string,
      inputAttrs: {
        placeholder: event.title,
        pattern: escapeRegExp(event.title),
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
       * When the event corresponding has been deleted (by the organizer).
       * A notification is already triggered.
       *
       * @type {string}
       */
      this.$emit("eventDeleted", event.id);

      this.$buefy.notification.open({
        message: this.$t("Event {eventTitle} deleted", { eventTitle }) as string,
        type: "is-success",
        position: "is-bottom-right",
        duration: 5000,
      });
      await this.$router.push({ name: RouteName.HOME });
    } catch (error) {
      console.error(error);
    }
  }

  urlToHostname(url: string): string | null {
    try {
      return new URL(url).hostname;
    } catch (e) {
      return null;
    }
  }
}
