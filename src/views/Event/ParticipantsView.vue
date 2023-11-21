<template>
  <section class="container mx-auto" v-if="event">
    <breadcrumbs-nav
      :links="[
        { name: RouteName.MY_EVENTS, text: t('My events') },
        {
          name: RouteName.EVENT,
          params: { uuid: event.uuid },
          text: event.title,
        },
        {
          name: RouteName.PARTICIPATIONS,
          params: { uuid: event.uuid },
          text: t('Participants'),
        },
      ]"
    />
    <h1>{{ t("Participants") }}</h1>
    <div class="">
      <div class="">
        <div class="">
          <o-field :label="t('Status')" horizontal label-for="role-select">
            <o-select v-model="role" id="role-select">
              <option value="EVERYTHING">
                {{ t("Everything") }}
              </option>
              <option :value="ParticipantRole.CREATOR">
                {{ t("Organizer") }}
              </option>
              <option :value="ParticipantRole.PARTICIPANT">
                {{ t("Participant") }}
              </option>
              <option :value="ParticipantRole.NOT_APPROVED">
                {{ t("Not approved") }}
              </option>
              <option :value="ParticipantRole.REJECTED">
                {{ t("Rejected") }}
              </option>
            </o-select>
          </o-field>
        </div>
        <div class="" v-if="exportFormats.length > 0">
          <o-dropdown aria-role="list">
            <template #trigger="{ active }">
              <o-button
                :label="t('Export')"
                variant="primary"
                :icon-right="active ? 'menu-up' : 'menu-down'"
              />
            </template>

            <o-dropdown-item
              has-link
              v-for="format in exportFormats"
              :key="format"
              aria-role="listitem"
              @click="
                exportParticipants({
                  eventId: event.id ?? '',
                  format,
                })
              "
              @keyup.enter="
                exportParticipants({
                  eventId: event.id ?? '',
                  format,
                })
              "
            >
              <button class="dropdown-button">
                <o-icon :icon="formatToIcon(format)"></o-icon>
                {{ format }}
              </button>
            </o-dropdown-item>
          </o-dropdown>
        </div>
      </div>
    </div>
    <o-table
      :data="event.participants.elements"
      ref="queueTable"
      detailed
      detail-key="id"
      v-model:checked-rows="checkedRows"
      checkable
      :is-row-checkable="
        (row: IParticipant) => row.role !== ParticipantRole.CREATOR
      "
      checkbox-position="left"
      :show-detail-icon="false"
      :loading="participantsLoading"
      paginated
      :current-page="page"
      backend-pagination
      :pagination-simple="true"
      :aria-next-label="t('Next page')"
      :aria-previous-label="t('Previous page')"
      :aria-page-label="t('Page')"
      :aria-current-label="t('Current page')"
      :total="event.participants.total"
      :per-page="PARTICIPANTS_PER_PAGE"
      backend-sorting
      :default-sort-direction="'desc'"
      :default-sort="['insertedAt', 'desc']"
      @page-change="(newPage: number) => (page = newPage)"
      @sort="(field: string, order: string) => emit('sort', field, order)"
    >
      <o-table-column
        field="actor.preferredUsername"
        :label="t('Participant')"
        v-slot="props"
      >
        <article class="flex gap-2">
          <figure v-if="props.row.actor.avatar">
            <img
              class="rounded-full w-12 h-12 object-cover"
              :src="props.row.actor.avatar.url"
              alt=""
              height="48"
              width="48"
            />
          </figure>
          <Incognito
            v-else-if="props.row.actor.preferredUsername === 'anonymous'"
            :size="48"
          />
          <AccountCircle v-else :size="48" />
          <div>
            <div class="prose dark:prose-invert">
              <p v-if="props.row.actor.preferredUsername !== 'anonymous'">
                <span v-if="props.row.actor.name">{{
                  props.row.actor.name
                }}</span
                ><br />
                <span class="text-sm"
                  >@{{ usernameWithDomain(props.row.actor) }}</span
                >
              </p>
              <span v-else>
                {{ t("Anonymous participant") }}
              </span>
            </div>
          </div>
        </article>
      </o-table-column>
      <o-table-column field="role" :label="t('Role')" v-slot="props">
        <tag
          variant="primary"
          v-if="props.row.role === ParticipantRole.CREATOR"
        >
          {{ t("Organizer") }}
        </tag>
        <tag v-else-if="props.row.role === ParticipantRole.PARTICIPANT">
          {{ t("Participant") }}
        </tag>
        <tag v-else-if="props.row.role === ParticipantRole.NOT_CONFIRMED">
          {{ t("Not confirmed") }}
        </tag>
        <tag
          variant="warning"
          v-else-if="props.row.role === ParticipantRole.NOT_APPROVED"
        >
          {{ t("Not approved") }}
        </tag>
        <tag
          variant="danger"
          v-else-if="props.row.role === ParticipantRole.REJECTED"
        >
          {{ t("Rejected") }}
        </tag>
      </o-table-column>
      <o-table-column
        field="metadata.message"
        class="column-message"
        :label="t('Message')"
        v-slot="props"
      >
        <div
          @click="toggleQueueDetails(props.row)"
          :class="{
            'ellipsed-message':
              props.row.metadata.message.length > MESSAGE_ELLIPSIS_LENGTH,
          }"
          v-if="props.row.metadata && props.row.metadata.message"
        >
          <p v-if="props.row.metadata.message.length > MESSAGE_ELLIPSIS_LENGTH">
            {{ ellipsize(props.row.metadata.message) }}
          </p>
          <p v-else>
            {{ props.row.metadata.message }}
          </p>
          <button
            type="button"
            class="button is-text"
            v-if="props.row.metadata.message.length > MESSAGE_ELLIPSIS_LENGTH"
            @click.stop="toggleQueueDetails(props.row)"
          >
            {{
              openDetailedRows[props.row.id] ? t("View less") : t("View more")
            }}
          </button>
        </div>
        <p v-else class="has-text-grey-dark">
          {{ t("No message") }}
        </p>
      </o-table-column>
      <o-table-column field="insertedAt" :label="t('Date')" v-slot="props">
        <span class="text-center">
          {{ formatDateString(props.row.insertedAt) }}<br />{{
            formatTimeString(props.row.insertedAt)
          }}
        </span>
      </o-table-column>
      <template #detail="props">
        <article v-html="nl2br(props.row.metadata.message)" />
      </template>
      <template #empty>
        <EmptyContent icon="account-circle" :inline="true">
          {{ t("No participant matches the filters") }}
        </EmptyContent>
      </template>
      <template #bottom-left>
        <div class="flex gap-2">
          <o-button
            @click="acceptParticipants(checkedRows)"
            variant="success"
            :disabled="!canAcceptParticipants"
            outlined
          >
            {{
              t(
                "No participant to approve|Approve participant|Approve {number} participants",
                { number: checkedRows.length },
                checkedRows.length
              )
            }}
          </o-button>
          <o-button
            @click="refuseParticipants(checkedRows)"
            variant="danger"
            :disabled="!canRefuseParticipants"
            outlined
          >
            {{
              t(
                "No participant to reject|Reject participant|Reject {number} participants",
                { number: checkedRows.length },
                checkedRows.length
              )
            }}
          </o-button>
        </div>
      </template>
    </o-table>
    <EventConversations :event="event" class="my-6" />
    <NewPrivateMessage :event="event" />
  </section>
</template>

<script lang="ts" setup>
import { ParticipantRole } from "@/types/enums";
import { IParticipant } from "@/types/participant.model";
import { IEvent } from "@/types/event.model";
import {
  EXPORT_EVENT_PARTICIPATIONS,
  PARTICIPANTS,
  UPDATE_PARTICIPANT,
} from "@/graphql/event";
import { usernameWithDomain } from "@/types/actor";
import { nl2br } from "@/utils/html";
import { asyncForEach } from "@/utils/asyncForEach";
import RouteName from "@/router/name";
import { useCurrentActorClient } from "@/composition/apollo/actor";
import { useParticipantsExportFormats } from "@/composition/config";
import { useMutation, useQuery } from "@vue/apollo-composable";
import {
  integerTransformer,
  enumTransformer,
  useRouteQuery,
} from "vue-use-route-query";
import { computed, inject, ref } from "vue";
import { formatDateString, formatTimeString } from "@/filters/datetime";
import { useI18n } from "vue-i18n";
import AccountCircle from "vue-material-design-icons/AccountCircle.vue";
import Incognito from "vue-material-design-icons/Incognito.vue";
import EmptyContent from "@/components/Utils/EmptyContent.vue";
import { Notifier } from "@/plugins/notifier";
import Tag from "@/components/TagElement.vue";
import { useHead } from "@unhead/vue";
import EventConversations from "../../components/Conversations/EventConversations.vue";
import NewPrivateMessage from "../../components/Participation/NewPrivateMessage.vue";

const PARTICIPANTS_PER_PAGE = 10;
const MESSAGE_ELLIPSIS_LENGTH = 130;

type exportFormat = "CSV" | "PDF" | "ODS";

const props = defineProps<{
  eventId: string;
}>();

const emit = defineEmits(["sort"]);

const { t } = useI18n({ useScope: "global" });

const { currentActor } = useCurrentActorClient();
const participantsExportFormats = useParticipantsExportFormats();

const ellipsize = (text?: string) =>
  text && text.substring(0, MESSAGE_ELLIPSIS_LENGTH).concat("…");

const eventId = computed(() => props.eventId);

const ParticipantAllRoles = { ...ParticipantRole, EVERYTHING: "EVERYTHING" };

const page = useRouteQuery("page", 1, integerTransformer);
const role = useRouteQuery(
  "role",
  "EVERYTHING",
  enumTransformer(ParticipantAllRoles)
);

const checkedRows = ref<IParticipant[]>([]);

const queueTable = ref();

const { result: participantsResult, loading: participantsLoading } = useQuery<{
  event: IEvent;
}>(
  PARTICIPANTS,
  () => ({
    uuid: eventId.value,
    page: page.value,
    limit: PARTICIPANTS_PER_PAGE,
    roles: role.value === "EVERYTHING" ? undefined : role.value,
  }),
  () => ({
    enabled:
      currentActor.value?.id !== undefined &&
      page.value !== undefined &&
      role.value !== undefined,
  })
);

const event = computed(() => participantsResult.value?.event);

// const participantStats = computed((): IEventParticipantStats | null => {
//   if (!event.value) return null;
//   return event.value.participantStats;
// });

const { mutate: updateParticipant, onError: onUpdateParticipantError } =
  useMutation(UPDATE_PARTICIPANT);

onUpdateParticipantError((e) => console.error(e));

const acceptParticipants = async (
  participants: IParticipant[]
): Promise<void> => {
  await asyncForEach(participants, async (participant: IParticipant) => {
    await updateParticipant({
      id: participant.id,
      role: ParticipantRole.PARTICIPANT,
    });
  });
  checkedRows.value = [];
};

const refuseParticipants = async (
  participants: IParticipant[]
): Promise<void> => {
  await asyncForEach(participants, async (participant: IParticipant) => {
    await updateParticipant({
      id: participant.id,
      role: ParticipantRole.REJECTED,
    });
  });
  checkedRows.value = [];
};

const {
  mutate: exportParticipants,
  onDone: onExportParticipantsMutationDone,
  onError: onExportParticipantsMutationError,
} = useMutation<
  { exportEventParticipants: { path: string; format: string } },
  { eventId: string; format?: exportFormat; roles?: string[] }
>(EXPORT_EVENT_PARTICIPATIONS);

onExportParticipantsMutationDone(({ data }) => {
  const path = data?.exportEventParticipants?.path;
  const format = data?.exportEventParticipants?.format;
  const link = window.origin + "/exports/" + format?.toLowerCase() + "/" + path;
  console.debug(link);
  const a = document.createElement("a");
  a.style.display = "none";
  document.body.appendChild(a);
  a.href = link;
  a.setAttribute("download", "true");
  a.click();
  window.URL.revokeObjectURL(a.href);
  document.body.removeChild(a);
});

const notifier = inject<Notifier>("notifier");

onExportParticipantsMutationError((e) => {
  console.error(e);
  if (e.graphQLErrors && e.graphQLErrors.length > 0) {
    notifier?.error(e.graphQLErrors[0].message);
  }
});

const exportFormats = computed((): exportFormat[] => {
  return (participantsExportFormats ?? []).map(
    (key) => key.toUpperCase() as exportFormat
  );
});

const formatToIcon = (format: exportFormat): string => {
  switch (format) {
    case "CSV":
      return "file-delimited";
    case "PDF":
      return "file-pdf-box";
    case "ODS":
      return "google-spreadsheet";
  }
};

/**
 * We can accept participants if at least one of them is not approved
 */
const canAcceptParticipants = (): boolean => {
  return checkedRows.value.some((participant: IParticipant) =>
    [ParticipantRole.NOT_APPROVED, ParticipantRole.REJECTED].includes(
      participant.role
    )
  );
};

/**
 * We can refuse participants if at least one of them is something different than not approved
 */
const canRefuseParticipants = (): boolean => {
  return checkedRows.value.some(
    (participant: IParticipant) => participant.role !== ParticipantRole.REJECTED
  );
};

const toggleQueueDetails = (row: IParticipant): void => {
  if (
    row.metadata.message &&
    row.metadata.message.length < MESSAGE_ELLIPSIS_LENGTH
  )
    return;
  queueTable.value.toggleDetails(row);
  if (row.id) {
    openDetailedRows.value[row.id] = !openDetailedRows.value[row.id];
  }
};

const openDetailedRows = ref<Record<string, boolean>>({});

useHead({
  title: computed(() =>
    t("Participants to {eventTitle}", { eventTitle: event.value?.title })
  ),
});
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style lang="scss" scoped>
section.container.container {
  padding: 1rem;
}

.table {
  .column-message {
    vertical-align: middle;
  }
  .ellipsed-message {
    cursor: pointer;
    display: flex;
    align-items: center;
    flex-wrap: wrap;
    justify-content: center;

    p {
      flex: 1;
      min-width: 200px;
    }

    button {
      display: inline;
    }
  }
}

nav.breadcrumb {
  a {
    text-decoration: none;
  }
}
</style>
