<template>
  <section class="container mx-auto max-w-2xl">
    <h2 class="text-2xl">
      {{ t("You wish to participate to the following event") }}
    </h2>
    <EventListViewCard v-if="event" :event="event" />
    <div class="flex flex-wrap gap-4 items-center w-full my-6">
      <div class="bg-white dark:bg-zinc-700 rounded-md p-4 flex-1">
        <router-link :to="{ name: RouteName.EVENT_PARTICIPATE_WITH_ACCOUNT }">
          <figure class="flex justify-center my-2">
            <img
              src="/img/undraw_profile.svg"
              alt="Profile illustration"
              width="128"
              height="128"
            />
          </figure>
          <o-button variant="primary">{{
            t("I have a Mobilizon account")
          }}</o-button>
        </router-link>
        <p>
          <small>
            {{
              t("Either on the {instance} instance or on another instance.", {
                instance: host,
              })
            }}
          </small>
          <o-tooltip
            variant="dark"
            :label="
              t(
                'Mobilizon is a federated network. You can interact with this event from a different server.'
              )
            "
          >
            <o-icon size="small" icon="help-circle-outline" />
          </o-tooltip>
        </p>
      </div>
      <div
        class="bg-white dark:bg-zinc-700 rounded-md p-4 flex-1"
        v-if="
          event &&
          anonymousParticipationAllowed &&
          hasAnonymousEmailParticipationMethod
        "
      >
        <router-link
          :to="{ name: RouteName.EVENT_PARTICIPATE_WITHOUT_ACCOUNT }"
          v-if="event.local"
        >
          <figure class="flex justify-center my-2">
            <img
              width="128"
              height="128"
              src="/img/undraw_mail_2.svg"
              alt="Privacy illustration"
            />
          </figure>
          <o-button variant="primary">{{
            t("I don't have a Mobilizon account")
          }}</o-button>
        </router-link>
        <a :href="`${event.url}/participate/without-account`" v-else>
          <figure class="flex justify-center my-2">
            <img
              src="/img/undraw_mail_2.svg"
              width="128"
              height="128"
              alt="Privacy illustration"
            />
          </figure>
          <o-button variant="primary">{{
            t("I don't have a Mobilizon account")
          }}</o-button>
        </a>
        <p>
          <small>{{ t("Participate using your email address") }}</small>
          <br />
          <small v-if="!event.local">
            {{ t("You will be redirected to the original instance") }}
          </small>
        </p>
      </div>
    </div>
    <div class="has-text-centered">
      <o-button tag="a" variant="text" @click="router.go(-1)">{{
        t("Back to previous page")
      }}</o-button>
    </div>
  </section>
</template>
<script lang="ts" setup>
import EventListViewCard from "@/components/Event/EventListViewCard.vue";
import RouteName from "../../router/name";
import { useFetchEvent } from "@/composition/apollo/event";
import { useAnonymousParticipationConfig } from "@/composition/apollo/config";
import { computed } from "vue";
import { useRouter } from "vue-router";
import { useHead } from "@unhead/vue";
import { useI18n } from "vue-i18n";

const props = defineProps<{ uuid: string }>();

const { event } = useFetchEvent(computed(() => props.uuid));

const { anonymousParticipationConfig } = useAnonymousParticipationConfig();

const router = useRouter();

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => t("Unlogged participation")),
  meta: [{ name: "robots", content: "noindex" }],
});

const host = computed((): string => {
  return window.location.hostname;
});

const anonymousParticipationAllowed = computed((): boolean | undefined => {
  return event.value?.options.anonymousParticipation;
});

const hasAnonymousEmailParticipationMethod = computed(
  (): boolean | undefined => {
    return (
      anonymousParticipationConfig.value?.allowed &&
      anonymousParticipationConfig.value?.validation.email.enabled
    );
  }
);
</script>
<style lang="scss" scoped>
.column > a {
  display: flex;
  flex-direction: column;
  align-items: center;
}
</style>
