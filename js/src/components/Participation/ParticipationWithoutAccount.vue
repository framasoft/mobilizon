<template>
  <section class="container section hero is-fullheight">
    <div class="hero-body" v-if="event">
      <div class="container">
        <form @submit.prevent="joinEvent">
          <p>
            {{
              $t(
                "This Mobilizon instance and this event organizer allows anonymous participations, but requires validation through email confirmation."
              )
            }}
          </p>
          <b-message type="is-info">
            {{
              $t(
                "Your email will only be used to confirm that you're a real person and send you eventual updates for this event. It will NOT be transmitted to other instances or to the event organizer."
              )
            }}
          </b-message>
          <b-message type="is-danger" v-if="error">{{ error }}</b-message>
          <b-field :label="$t('Email')">
            <b-input
              type="email"
              v-model="anonymousParticipation.email"
              placeholder="Your email"
              required
            ></b-input>
          </b-field>
          <p v-if="event.joinOptions === EventJoinOptions.RESTRICTED">
            {{
              $t(
                "The event organizer manually approves participations. Since you've chosen to participate without an account, please explain why you want to participate to this event."
              )
            }}
          </p>
          <p v-else>{{ $t("If you want, you may send a message to the event organizer here.") }}</p>
          <b-field :label="$t('Message')">
            <b-input
              type="textarea"
              v-model="anonymousParticipation.message"
              minlength="10"
              :required="event.joinOptions === EventJoinOptions.RESTRICTED"
            ></b-input>
          </b-field>
          <b-button type="is-primary" native-type="submit">{{ $t("Send email") }}</b-button>
          <div class="has-text-centered">
            <b-button native-type="button" tag="a" type="is-text" @click="$router.go(-1)">{{
              $t("Back to previous page")
            }}</b-button>
          </div>
        </form>
      </div>
    </div>
  </section>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import {
  EventModel,
  IEvent,
  IParticipant,
  ParticipantRole,
  EventJoinOptions,
} from "@/types/event.model";
import { FETCH_EVENT, JOIN_EVENT } from "@/graphql/event";
import { IConfig } from "@/types/config.model";
import { CONFIG } from "@/graphql/config";
import { addLocalUnconfirmedAnonymousParticipation } from "@/services/AnonymousParticipationStorage";
import RouteName from "../../router/name";

@Component({
  apollo: {
    event: {
      query: FETCH_EVENT,
      variables() {
        return {
          uuid: this.uuid,
        };
      },
      skip() {
        return !this.uuid;
      },
      update: (data) => new EventModel(data.event),
    },
    config: CONFIG,
  },
})
export default class ParticipationWithoutAccount extends Vue {
  @Prop({ type: String, required: true }) uuid!: string;

  anonymousParticipation: { email: string; message: string } = {
    email: "",
    message: "",
  };

  event!: IEvent;

  config!: IConfig;

  error: string | boolean = false;

  EventJoinOptions = EventJoinOptions;

  async joinEvent() {
    this.error = false;
    try {
      const { data } = await this.$apollo.mutate<{ joinEvent: IParticipant }>({
        mutation: JOIN_EVENT,
        variables: {
          eventId: this.event.id,
          actorId: this.config.anonymous.actorId,
          email: this.anonymousParticipation.email,
          message: this.anonymousParticipation.message,
          locale: this.$i18n.locale,
        },
        update: (store, { data }) => {
          if (data == null) {
            console.error("Cannot update event participant cache, because of data null value.");
            return;
          }

          const cachedData = store.readQuery<{ event: IEvent }>({
            query: FETCH_EVENT,
            variables: { uuid: this.event.uuid },
          });
          if (cachedData == null) {
            console.error("Cannot update event participant cache, because of cached null value.");
            return;
          }
          const { event } = cachedData;
          if (event === null) {
            console.error("Cannot update event participant cache, because of null value.");
            return;
          }

          if (data.joinEvent.role === ParticipantRole.NOT_CONFIRMED) {
            event.participantStats.notConfirmed = event.participantStats.notConfirmed + 1;
          } else {
            event.participantStats.going = event.participantStats.going + 1;
            event.participantStats.participant = event.participantStats.participant + 1;
          }
          console.log("just before writequery");

          store.writeQuery({
            query: FETCH_EVENT,
            variables: { uuid: this.event.uuid },
            data: { event },
          });
        },
      });
      console.log("finished with store", data);
      if (data && data.joinEvent.metadata.cancellationToken) {
        await addLocalUnconfirmedAnonymousParticipation(
          this.event,
          data.joinEvent.metadata.cancellationToken
        );
        console.log("done with crypto stuff");
      }
    } catch (e) {
      console.error(e);
      if (e.message === "GraphQL error: You are already a participant of this event") {
        this.error = this.$t(
          "This email is already registered as participant for this event"
        ) as string;
      }
    } finally {
      return this.$router.push({
        name: RouteName.EVENT,
        params: { uuid: this.event.uuid },
      });
    }
  }
}
</script>
