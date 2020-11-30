<template>
  <section class="section container hero">
    <div class="hero-body" v-if="event">
      <div class="container">
        <subtitle>{{
          $t("You wish to participate to the following event")
        }}</subtitle>
        <EventListViewCard v-if="event" :event="event" />
        <div class="columns has-text-centered">
          <div class="column">
            <router-link
              :to="{ name: RouteName.EVENT_PARTICIPATE_WITH_ACCOUNT }"
            >
              <figure class="image is-128x128">
                <img
                  src="../../assets/undraw_profile.svg"
                  alt="Profile illustration"
                />
              </figure>
              <b-button type="is-primary">{{
                $t("I have a Mobilizon account")
              }}</b-button>
            </router-link>
            <p>
              <small>
                {{
                  $t(
                    "Either on the {instance} instance or on another instance.",
                    {
                      instance: host,
                    }
                  )
                }}
              </small>
              <b-tooltip
                type="is-dark"
                :label="
                  $t(
                    'Mobilizon is a federated network. You can interact with this event from a different server.'
                  )
                "
              >
                <b-icon size="is-small" icon="help-circle-outline" />
              </b-tooltip>
            </p>
          </div>
          <vertical-divider
            :content="$t('Or')"
            v-if="anonymousParticipationAllowed"
          />
          <div
            class="column"
            v-if="
              anonymousParticipationAllowed &&
              hasAnonymousEmailParticipationMethod
            "
          >
            <router-link
              :to="{ name: RouteName.EVENT_PARTICIPATE_WITHOUT_ACCOUNT }"
              v-if="event.local"
            >
              <figure class="image is-128x128">
                <img
                  src="../../assets/undraw_mail_2.svg"
                  alt="Privacy illustration"
                />
              </figure>
              <b-button type="is-primary">{{
                $t("I don't have a Mobilizon account")
              }}</b-button>
            </router-link>
            <a :href="`${event.url}/participate/without-account`" v-else>
              <figure class="image is-128x128">
                <img
                  src="../../assets/undraw_mail_2.svg"
                  alt="Privacy illustration"
                />
              </figure>
              <b-button type="is-primary">{{
                $t("I don't have a Mobilizon account")
              }}</b-button>
            </a>
            <p>
              <small>{{ $t("Participate using your email address") }}</small>
              <br />
              <small v-if="!event.local">
                {{ $t("You will be redirected to the original instance") }}
              </small>
            </p>
          </div>
        </div>
        <div class="has-text-centered">
          <b-button tag="a" type="is-text" @click="$router.go(-1)">{{
            $t("Back to previous page")
          }}</b-button>
        </div>
      </div>
    </div>
  </section>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { FETCH_EVENT } from "@/graphql/event";
import EventListViewCard from "@/components/Event/EventListViewCard.vue";
import { EventModel, IEvent } from "@/types/event.model";
import VerticalDivider from "@/components/Utils/VerticalDivider.vue";
import { CONFIG } from "@/graphql/config";
import { IConfig } from "@/types/config.model";
import Subtitle from "@/components/Utils/Subtitle.vue";
import RouteName from "../../router/name";

@Component({
  components: {
    VerticalDivider,
    EventListViewCard,
    Subtitle,
  },
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
export default class UnloggedParticipation extends Vue {
  @Prop({ type: String, required: true }) uuid!: string;

  RouteName = RouteName;

  event!: IEvent;

  config!: IConfig;

  // eslint-disable-next-line class-methods-use-this
  get host(): string {
    return window.location.hostname;
  }

  get anonymousParticipationAllowed(): boolean {
    return this.event.options.anonymousParticipation;
  }

  get hasAnonymousEmailParticipationMethod(): boolean {
    return (
      this.config.anonymous.participation.allowed &&
      this.config.anonymous.participation.validation.email.enabled
    );
  }
}
</script>
<style lang="scss" scoped>
.column > a {
  display: flex;
  flex-direction: column;
  align-items: center;
}
</style>
