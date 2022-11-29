<template>
  <section class="container mx-auto">
    <div class="" v-if="event">
      <form @submit.prevent="joinEvent" v-if="!formSent">
        <p>
          {{
            $t(
              "This Mobilizon instance and this event organizer allows anonymous participations, but requires validation through email confirmation."
            )
          }}
        </p>
        <o-notification variant="info">
          {{
            $t(
              "Your email will only be used to confirm that you're a real person and send you eventual updates for this event. It will NOT be transmitted to other instances or to the event organizer."
            )
          }}
        </o-notification>
        <o-notification variant="danger" v-if="error">{{
          error
        }}</o-notification>
        <o-field
          :label="$t('Email address')"
          labelFor="anonymousParticipationEmail"
        >
          <o-input
            type="email"
            id="anonymousParticipationEmail"
            v-model="anonymousParticipation.email"
            :placeholder="$t('Your email')"
            required
          />
        </o-field>
        <p v-if="event.joinOptions === EventJoinOptions.RESTRICTED">
          {{
            $t(
              "The event organizer manually approves participations. Since you've chosen to participate without an account, please explain why you want to participate to this event."
            )
          }}
        </p>
        <p v-else>
          {{
            $t(
              "If you want, you may send a message to the event organizer here."
            )
          }}
        </p>
        <o-field
          :label="$t('Message')"
          labelFor="anonymousParticipationMessage"
        >
          <o-input
            id="anonymousParticipationMessage"
            type="textarea"
            v-model="anonymousParticipation.message"
            minlength="10"
            :required="event.joinOptions === EventJoinOptions.RESTRICTED"
          />
        </o-field>
        <o-field>
          <o-checkbox v-model="anonymousParticipation.saveParticipation">
            <b>{{ $t("Remember my participation in this browser") }}</b>
            <p>
              {{
                $t(
                  "Will allow to display and manage your participation status on the event page when using this device. Uncheck if you're using a public device."
                )
              }}
            </p>
          </o-checkbox>
        </o-field>
        <div class="flex gap-2 my-2">
          <o-button
            :disabled="sendingForm"
            variant="primary"
            native-type="submit"
            >{{ $t("Send email") }}</o-button
          >
          <o-button
            native-type="button"
            variant="text"
            @click="$router.go(-1)"
            >{{ $t("Back to previous page") }}</o-button
          >
        </div>
      </form>
      <div v-else>
        <h1 class="title">
          {{ $t("Request for participation confirmation sent") }}
        </h1>
        <p class="prose dark:prose-invert">
          <span>{{ $t("Check your inbox (and your junk mail folder).") }}</span>
          <span
            class="details"
            v-if="event.joinOptions === EventJoinOptions.RESTRICTED"
          >
            {{
              $t(
                "Your participation will be validated once you click the confirmation link into the email, and after the organizer manually validates your participation."
              )
            }} </span
          ><span class="details" v-else>{{
            $t(
              "Your participation will be validated once you click the confirmation link into the email."
            )
          }}</span>
        </p>
        <o-notification variant="warning" v-if="error">{{
          error
        }}</o-notification>
        <p class="prose dark:prose-invert">
          <i18n-t
            keypath="You may now close this window, or {return_to_event}."
          >
            <template #return_to_event>
              <router-link
                :to="{ name: RouteName.EVENT, params: { uuid: event.uuid } }"
                >{{ $t("return to the event's page") }}</router-link
              >
            </template>
          </i18n-t>
        </p>
      </div>
    </div>
    <o-notification variant="danger" v-else-if="!loading"
      >{{
        $t(
          "Unable to load event for participation. The error details are provided below:"
        )
      }}
      <details>
        <pre>{{ error }}</pre>
      </details>
    </o-notification>
  </section>
</template>
<script lang="ts" setup>
import { IEvent } from "@/types/event.model";
import { FETCH_EVENT_BASIC, JOIN_EVENT } from "@/graphql/event";
import { addLocalUnconfirmedAnonymousParticipation } from "@/services/AnonymousParticipationStorage";
import { EventJoinOptions, ParticipantRole } from "@/types/enums";
import RouteName from "@/router/name";
import { IParticipant } from "../../types/participant.model";
import { ApolloCache, FetchResult } from "@apollo/client/core";
import { useFetchEventBasic } from "@/composition/apollo/event";
import { useAnonymousActorId } from "@/composition/apollo/config";
import { computed, reactive, ref } from "vue";
import { useI18n } from "vue-i18n";
import { useHead } from "@vueuse/head";
import { useMutation } from "@vue/apollo-composable";

const error = ref<boolean | string>(false);

const { anonymousActorId } = useAnonymousActorId();

const props = defineProps<{
  uuid: string;
}>();
const { event, loading } = useFetchEventBasic(props.uuid);

const { t, locale } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => t("Participation without account")),
  meta: [{ name: "robots", content: "noindex" }],
});

const anonymousParticipation = reactive<{
  email: string;
  message: string;
  saveParticipation: boolean;
}>({
  email: "",
  message: "",
  saveParticipation: true,
});

const formSent = ref(false);

const sendingForm = ref(false);

const {
  mutate: joinEventMutation,
  onDone: joinEventDone,
  onError: joinEventError,
} = useMutation<{
  joinEvent: IParticipant;
}>(JOIN_EVENT, () => ({
  update: (
    store: ApolloCache<{ joinEvent: IParticipant }>,
    { data: updateData }: FetchResult
  ) => {
    if (updateData == null) {
      console.error(
        "Cannot update event participant cache, because of data null value."
      );
      return;
    }

    const cachedData = store.readQuery<{ event: IEvent }>({
      query: FETCH_EVENT_BASIC,
      variables: { uuid: event.value?.uuid },
    });
    if (cachedData == null) {
      console.error(
        "Cannot update event participant cache, because of cached null value."
      );
      return;
    }
    const participantStats = { ...cachedData.event.participantStats };

    if (updateData.joinEvent.role === ParticipantRole.NOT_CONFIRMED) {
      participantStats.notConfirmed += 1;
    } else {
      participantStats.going += 1;
      participantStats.participant += 1;
    }

    store.writeQuery({
      query: FETCH_EVENT_BASIC,
      variables: { uuid: event.value?.uuid },
      data: {
        event: {
          ...cachedData.event,
          participantStats,
        },
      },
    });
  },
}));

joinEventDone(async ({ data }) => {
  sendingForm.value = false;
  formSent.value = true;
  if (
    data?.joinEvent.metadata.cancellationToken &&
    anonymousParticipation.saveParticipation &&
    event.value
  ) {
    try {
      await addLocalUnconfirmedAnonymousParticipation(
        event.value,
        data.joinEvent.metadata.cancellationToken
      );
    } catch (e: any) {
      if (
        ["TextEncoder is not defined", "crypto.subtle is undefined"].includes(
          e.message
        )
      ) {
        error.value = t("Unable to save your participation in this browser.");
      }
    }
  }
});

joinEventError((e) => {
  if (e.graphQLErrors && e.graphQLErrors.length > 0) {
    error.value = e.graphQLErrors[0].message;
  } else if (e.networkError) {
    error.value = e.networkError.message;
  }
});

const joinEvent = async (): Promise<void> => {
  error.value = false;
  sendingForm.value = true;
  joinEventMutation({
    eventId: event.value?.id,
    actorId: anonymousActorId.value,
    email: anonymousParticipation.email,
    message: anonymousParticipation.message,
    locale: locale,
    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
  });
};
</script>
