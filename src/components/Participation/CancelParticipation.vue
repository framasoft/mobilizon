<template>
  <section class="container mx-auto">
    <h1 class="title" v-if="loading">
      {{ t("Your participation is being cancelled") }}
    </h1>
    <div v-else>
      <div v-if="failed && !leftEvent">
        <o-notification
          :title="t('Error while cancelling your participation')"
          variant="danger"
        >
          {{
            t(
              "Either your participation has already been cancelled, either the validation token is incorrect."
            )
          }}
        </o-notification>
      </div>
      <div v-else-if="leftEvent">
        <h1 class="title">
          {{ t("Your participation has been cancelled") }}
        </h1>
        <div class="columns has-text-centered">
          <div class="column">
            <o-button
              tag="router-link"
              variant="primary"
              size="large"
              :to="{
                name: RouteName.EVENT,
                params: { uuid: leftEvent.uuid },
              }"
              >{{ t("Return to the event page") }}</o-button
            >
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script lang="ts" setup>
import RouteName from "../../router/name";
import { LEAVE_EVENT } from "../../graphql/event";
import { computed, ref, watchEffect } from "vue";
import { useMutation } from "@vue/apollo-composable";
import { useI18n } from "vue-i18n";
import { useHead } from "@unhead/vue";
import { IActor } from "@/types/actor";
import { IEvent } from "@/types/event.model";
import { useAnonymousActorId } from "@/composition/apollo/config";
import { useFetchEventBasic } from "@/composition/apollo/event";

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => t("Confirm participation")),
});

const props = defineProps<{
  uuid: string;
  token: string;
}>();

const participationToken = computed(() => props.token);
const eventUUID = computed(() => props.uuid);

const loading = ref(true);
const failed = ref(false);
const leftEvent = ref<IEvent | null>(null);
const { anonymousActorId } = useAnonymousActorId();

const { event } = useFetchEventBasic(eventUUID);

const { onDone, onError, mutate } = useMutation<{
  leaveEvent: {
    id: string;
    actor: IActor;
    event: IEvent;
  };
}>(LEAVE_EVENT);

watchEffect(() => {
  if (participationToken.value && event.value) {
    mutate({
      token: participationToken.value,
      eventId: event.value.id,
      actorId: anonymousActorId.value,
    });
  }
});

onDone(async ({ data }) => {
  if (data?.leaveEvent.event) {
    leftEvent.value = data?.leaveEvent.event;
  } else {
    failed.value = true;
  }
  loading.value = false;
});

onError((err) => {
  console.error(err);
  failed.value = true;
  loading.value = false;
});
</script>
