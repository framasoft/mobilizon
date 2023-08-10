<template>
  <section class="container mx-auto">
    <h1 class="title" v-if="loading">
      {{ t("Your participation request is being validated") }}
    </h1>
    <div v-else>
      <div v-if="failed && participation === undefined">
        <o-notification
          :title="t('Error while validating participation request')"
          variant="danger"
        >
          {{
            t(
              "Either the participation request has already been validated, either the validation token is incorrect."
            )
          }}
        </o-notification>
      </div>
      <div v-else>
        <h1 class="title">
          {{ t("Your participation request has been validated") }}
        </h1>
        <p
          class="prose dark:prose-invert"
          v-if="participation?.event.joinOptions == EventJoinOptions.RESTRICTED"
        >
          {{
            t("Your participation still has to be approved by the organisers.")
          }}
        </p>
        <div v-if="failed">
          <o-notification
            :title="
              t('Error while updating participation status inside this browser')
            "
            variant="warning"
          >
            {{
              t(
                "We couldn't save your participation inside this browser. Not to worry, you have successfully confirmed your participation, we just couldn't save it's status in this browser because of a technical issue."
              )
            }}
          </o-notification>
        </div>
        <div class="columns has-text-centered">
          <div class="column">
            <o-button
              tag="router-link"
              variant="primary"
              size="large"
              :to="{
                name: RouteName.EVENT,
                params: { uuid: participation?.event.uuid },
              }"
              >{{ t("Go to the event page") }}</o-button
            >
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script lang="ts" setup>
import { confirmLocalAnonymousParticipation } from "@/services/AnonymousParticipationStorage";
import { EventJoinOptions } from "@/types/enums";
import { IParticipant } from "../../types/participant.model";
import RouteName from "../../router/name";
import { CONFIRM_PARTICIPATION } from "../../graphql/event";
import { computed, ref } from "vue";
import { useMutation } from "@vue/apollo-composable";
import { useI18n } from "vue-i18n";
import { useHead } from "@vueuse/head";

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => t("Confirm participation")),
});

const props = defineProps<{
  token: string;
}>();

const loading = ref(true);
const failed = ref(false);
const participation = ref<IParticipant | null | undefined>(null);

const { onDone, onError, mutate } = useMutation<{
  confirmParticipation: IParticipant;
}>(CONFIRM_PARTICIPATION);

mutate(() => ({
  token: props.token,
}));

onDone(async ({ data }) => {
  participation.value = data?.confirmParticipation;
  if (participation.value) {
    await confirmLocalAnonymousParticipation(participation.value?.event.uuid);
  }
  loading.value = false;
});

onError((err) => {
  console.error(err);
  failed.value = true;
  loading.value = false;
});
</script>
