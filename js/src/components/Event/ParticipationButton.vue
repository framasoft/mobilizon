import {EventJoinOptions} from "@/types/event.model";
<docs>
A button to set your participation

##### If the participant has been confirmed
```vue
<ParticipationButton :participation="{ role: 'PARTICIPANT' }" :currentActor="{ preferredUsername: 'test', avatar: { url: 'https://huit.re/EPX7vs1j' } }" />
```

##### If the participant has not being approved yet
```vue
<ParticipationButton :participation="{ role: 'NOT_APPROVED' }" :currentActor="{ preferredUsername: 'test', avatar: { url: 'https://huit.re/EPX7vs1j' } }" />
```

##### If the participant has been rejected
```vue
<ParticipationButton :participation="{ role: 'REJECTED' }" :currentActor="{ preferredUsername: 'test', avatar: { url: 'https://huit.re/EPX7vs1j' } }" />
```

##### If the participant doesn't exist yet
```vue
<ParticipationButton :participation="null" :currentActor="{ preferredUsername: 'test', avatar: { url: 'https://huit.re/EPX7vs1j' } }" />
```
</docs>

<template>
  <div class="participation-button">
    <b-dropdown
      aria-role="list"
      position="is-bottom-left"
      v-if="participation && participation.role === ParticipantRole.PARTICIPANT"
    >
      <button class="button is-success is-large" type="button" slot="trigger">
        <b-icon icon="check" />
        <template>
          <span>{{ $t("I participate") }}</span>
        </template>
        <b-icon icon="menu-down" />
      </button>

      <b-dropdown-item
        :value="false"
        aria-role="listitem"
        @click="confirmLeave"
        class="has-text-danger"
        >{{ $t("Cancel my participation…") }}</b-dropdown-item
      >
    </b-dropdown>

    <div
      v-else-if="
        participation && participation.role === ParticipantRole.NOT_APPROVED
      "
    >
      <b-dropdown
        aria-role="list"
        position="is-bottom-left"
        class="dropdown-disabled"
      >
        <button class="button is-success is-large" type="button" slot="trigger">
          <b-icon icon="timer-sand-empty" />
          <template>
            <span>{{ $t("I participate") }}</span>
          </template>
          <b-icon icon="menu-down" />
        </button>

        <!--                <b-dropdown-item :value="false" aria-role="listitem">-->
        <!--                  {{ $t('Change my identity…')}}-->
        <!--                </b-dropdown-item>-->

        <b-dropdown-item
          :value="false"
          aria-role="listitem"
          @click="confirmLeave"
          class="has-text-danger"
          >{{ $t("Cancel my participation request…") }}</b-dropdown-item
        >
      </b-dropdown>
      <small>{{ $t("Participation requested!") }}</small>
      <br />
      <small>{{ $t("Waiting for organization team approval.") }}</small>
    </div>

    <div
      v-else-if="
        participation && participation.role === ParticipantRole.REJECTED
      "
    >
      <span>
        {{
          $t(
            "Unfortunately, your participation request was rejected by the organizers."
          )
        }}
      </span>
    </div>

    <b-dropdown
      aria-role="list"
      position="is-bottom-left"
      v-else-if="!participation && currentActor.id"
    >
      <button class="button is-primary is-large" type="button" slot="trigger">
        <template>
          <span>{{ $t("Participate") }}</span>
        </template>
        <b-icon icon="menu-down" />
      </button>

      <b-dropdown-item
        :value="true"
        aria-role="listitem"
        @click="joinEvent(currentActor)"
      >
        <div class="media">
          <div class="media-left">
            <figure class="image is-32x32" v-if="currentActor.avatar">
              <img class="is-rounded" :src="currentActor.avatar.url" alt />
            </figure>
          </div>
          <div class="media-content">
            <span>
              {{
                $t("as {identity}", {
                  identity:
                    currentActor.name || `@${currentActor.preferredUsername}`,
                })
              }}
            </span>
          </div>
        </div>
      </b-dropdown-item>

      <b-dropdown-item
        :value="false"
        aria-role="listitem"
        @click="joinModal"
        v-if="identities.length > 1"
        >{{ $t("with another identity…") }}</b-dropdown-item
      >
    </b-dropdown>
    <b-button
      tag="router-link"
      :to="{
        name: RouteName.EVENT_PARTICIPATE_LOGGED_OUT,
        params: { uuid: event.uuid },
      }"
      v-else-if="!participation && hasAnonymousParticipationMethods"
      type="is-primary"
      size="is-large"
      native-type="button"
      >{{ $t("Participate") }}</b-button
    >
    <b-button
      tag="router-link"
      :to="{
        name: RouteName.EVENT_PARTICIPATE_WITH_ACCOUNT,
        params: { uuid: event.uuid },
      }"
      v-else-if="!currentActor.id"
      type="is-primary"
      size="is-large"
      native-type="button"
      >{{ $t("Participate") }}</b-button
    >
  </div>
</template>

<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { EventJoinOptions, ParticipantRole } from "@/types/enums";
import { IParticipant } from "../../types/participant.model";
import { IEvent } from "../../types/event.model";
import { IPerson, Person } from "../../types/actor";
import { CURRENT_ACTOR_CLIENT, IDENTITIES } from "../../graphql/actor";
import { CURRENT_USER_CLIENT } from "../../graphql/user";
import { CONFIG } from "../../graphql/config";
import { IConfig } from "../../types/config.model";
import RouteName from "../../router/name";

@Component({
  apollo: {
    currentUser: {
      query: CURRENT_USER_CLIENT,
    },
    currentActor: CURRENT_ACTOR_CLIENT,
    config: CONFIG,
    identities: {
      query: IDENTITIES,
      update: ({ identities }) =>
        identities
          ? identities.map((identity: IPerson) => new Person(identity))
          : [],
      skip() {
        return this.currentUser.isLoggedIn === false;
      },
    },
  },
})
export default class ParticipationButton extends Vue {
  @Prop({ required: true }) participation!: IParticipant;

  @Prop({ required: true }) event!: IEvent;

  @Prop({ required: true }) currentActor!: IPerson;

  ParticipantRole = ParticipantRole;

  identities: IPerson[] = [];

  config!: IConfig;

  RouteName = RouteName;

  joinEvent(actor: IPerson): void {
    if (this.event.joinOptions === EventJoinOptions.RESTRICTED) {
      this.$emit("join-event-with-confirmation", actor);
    } else {
      this.$emit("join-event", actor);
    }
  }

  joinModal(): void {
    this.$emit("join-modal");
  }

  confirmLeave(): void {
    this.$emit("confirm-leave");
  }

  get hasAnonymousParticipationMethods(): boolean {
    return this.event.options.anonymousParticipation;
  }
}
</script>

<style lang="scss" scoped>
.participation-button {
  .dropdown {
    display: flex;
    justify-content: flex-end;

    &.dropdown-disabled button {
      opacity: 0.5;
    }
  }
}

.anonymousParticipationModal {
  ::v-deep .animation-content {
    z-index: 1;
  }
}
</style>
