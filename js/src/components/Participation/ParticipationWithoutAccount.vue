<template>
  <section class="container section hero is-fullheight">
    <div class="hero-body" v-if="event">
      <div class="container">
        <form @submit.prevent="joinEvent" v-if="!formSent">
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
          <b-field :label="$t('Email address')">
            <b-input
              type="email"
              v-model="anonymousParticipation.email"
              :placeholder="$t('Your email')"
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
          <b-field>
            <b-checkbox v-model="anonymousParticipation.saveParticipation">
              <b>{{ $t("Remember my participation in this browser") }}</b>
              <p>
                {{
                  $t(
                    "Will allow to display and manage your participation status on the event page when using this device. Uncheck if you're using a public device."
                  )
                }}
              </p>
            </b-checkbox>
          </b-field>
          <b-button :disabled="sendingForm" type="is-primary" native-type="submit">{{
            $t("Send email")
          }}</b-button>
          <div class="has-text-centered">
            <b-button native-type="button" tag="a" type="is-text" @click="$router.go(-1)">{{
              $t("Back to previous page")
            }}</b-button>
          </div>
        </form>
        <div v-else>
          <h1 class="title">{{ $t("Request for participation confirmation sent") }}</h1>
          <p class="content">{{ $t("Check your inbox (and your junk mail folder).") }}</p>
          <p class="content">{{ $t("You may now close this window.") }}</p>
        </div>
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
import { Route } from "vue-router";
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

  anonymousParticipation: { email: string; message: string; saveParticipation: boolean } = {
    email: "",
    message: "",
    saveParticipation: true,
  };

  event!: IEvent;

  config!: IConfig;

  error: string | boolean = false;

  formSent = false;

  sendingForm = false;

  EventJoinOptions = EventJoinOptions;

  async joinEvent(): Promise<void> {
    this.error = false;
    this.sendingForm = true;
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
            event.participantStats.notConfirmed += 1;
          } else {
            event.participantStats.going += 1;
            event.participantStats.participant += 1;
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
      if (
        data &&
        data.joinEvent.metadata.cancellationToken &&
        this.anonymousParticipation.saveParticipation
      ) {
        await addLocalUnconfirmedAnonymousParticipation(
          this.event,
          data.joinEvent.metadata.cancellationToken
        );
        console.log("done with crypto stuff");
      }
    } catch (e) {
      this.error = e.message;
    }
    this.sendingForm = false;
    this.formSent = true;
  }
}
</script>
