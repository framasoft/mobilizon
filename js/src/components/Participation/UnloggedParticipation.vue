<template>
  <section class="container mx-auto hero">
    <div class="hero-body" v-if="event">
      <div class="container mx-auto">
        <h2 class="text-2xl">
          {{ $t("You wish to participate to the following event") }}
        </h2>
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
              <o-button variant="primary">{{
                $t("I have a Mobilizon account")
              }}</o-button>
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
              <o-tooltip
                type="is-dark"
                :label="
                  $t(
                    'Mobilizon is a federated network. You can interact with this event from a different server.'
                  )
                "
              >
                <o-icon size="small" icon="help-circle-outline" />
              </o-tooltip>
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
              <o-button variant="primary">{{
                $t("I don't have a Mobilizon account")
              }}</o-button>
            </router-link>
            <a :href="`${event.url}/participate/without-account`" v-else>
              <figure class="image is-128x128">
                <img
                  src="../../assets/undraw_mail_2.svg"
                  alt="Privacy illustration"
                />
              </figure>
              <o-button variant="primary">{{
                $t("I don't have a Mobilizon account")
              }}</o-button>
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
          <o-button tag="a" type="is-text" @click="router.go(-1)">{{
            $t("Back to previous page")
          }}</o-button>
        </div>
      </div>
    </div>
  </section>
</template>
<script lang="ts" setup>
import EventListViewCard from "@/components/Event/EventListViewCard.vue";
import VerticalDivider from "@/components/Utils/VerticalDivider.vue";
import RouteName from "../../router/name";
import { useFetchEvent } from "@/composition/apollo/event";
import { useAnonymousParticipationConfig } from "@/composition/apollo/config";
import { computed } from "vue";
import { useRouter } from "vue-router";
import { useHead } from "@vueuse/head";
import { useI18n } from "vue-i18n";

const props = defineProps<{ uuid: string }>();

const { event } = useFetchEvent(props.uuid);

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
