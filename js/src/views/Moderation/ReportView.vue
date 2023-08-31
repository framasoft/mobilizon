<template>
  <breadcrumbs-nav
    v-if="report"
    :links="[
      {
        name: RouteName.MODERATION,
        text: t('Moderation'),
      },
      {
        name: RouteName.REPORTS,
        text: t('Reports'),
      },
      {
        name: RouteName.REPORT,
        params: { id: report.id },
        text: t('Report #{reportNumber}', { reportNumber: report.id }),
      },
    ]"
  />
  <o-notification
    title="Error"
    variant="danger"
    v-for="error in errors"
    :key="error"
  >
    {{ error }}
  </o-notification>
  <div class="container mx-auto" v-if="report">
    <div class="flex flex-wrap gap-2 my-2">
      <o-button
        v-if="report.status !== ReportStatusEnum.RESOLVED"
        @click="updateReport(ReportStatusEnum.RESOLVED)"
        variant="primary"
        >{{ t("Mark as resolved") }}</o-button
      >
      <o-button
        v-if="report.status !== ReportStatusEnum.OPEN"
        @click="updateReport(ReportStatusEnum.OPEN)"
        variant="success"
        >{{ t("Reopen") }}</o-button
      >
      <o-button
        v-if="report.status !== ReportStatusEnum.CLOSED"
        @click="updateReport(ReportStatusEnum.CLOSED)"
        variant="danger"
        >{{ t("Close") }}</o-button
      >
      <o-button
        v-if="antispamEnabled"
        outlined
        @click="reportToAntispam(true)"
        variant="text"
        class="!text-mbz-danger"
        >{{ t("Report as spam") }}</o-button
      >
      <o-button
        v-if="antispamEnabled"
        outlined
        @click="reportToAntispam(false)"
        variant="text"
        class="!text-mbz-success"
        >{{ t("Report as ham") }}</o-button
      >
    </div>
    <section class="w-full">
      <table class="table w-full">
        <tbody>
          <tr v-if="report.reported.type === ActorType.GROUP">
            <td>{{ t("Reported group") }}</td>
            <td>
              <router-link
                :to="{
                  name: RouteName.ADMIN_GROUP_PROFILE,
                  params: { id: report.reported.id },
                }"
              >
                <img
                  v-if="report.reported.avatar"
                  class="image"
                  :src="report.reported.avatar.url"
                  alt=""
                />
                {{ displayNameAndUsername(report.reported) }}
              </router-link>
            </td>
          </tr>
          <tr v-else>
            <td>
              {{ t("Reported identity") }}
            </td>
            <td class="flex items-center justify-between pr-6">
              <router-link
                :to="{
                  name: RouteName.ADMIN_PROFILE,
                  params: { id: report.reported.id },
                }"
              >
                <img
                  v-if="report.reported.avatar"
                  class="image"
                  :src="report.reported.avatar.url"
                  alt=""
                />
                {{ displayNameAndUsername(report.reported) }}
              </router-link>
              <o-button
                v-if="report.reported.domain"
                variant="danger"
                @click="suspendProfile(report.reported.id as string)"
                icon-left="delete"
                >{{ t("Suspend the profile") }}</o-button
              >
              <o-button
                v-else-if="(report.reported as IPerson).user"
                variant="danger"
                @click="suspendUser((report.reported as IPerson).user as IUser)"
                icon-left="delete"
                >{{ t("Suspend the account") }}</o-button
              >
            </td>
          </tr>
          <tr>
            <td>{{ t("Reported by") }}</td>
            <td v-if="report.reporter.type === ActorType.APPLICATION">
              {{ report.reporter.domain }}
            </td>
            <td v-else>
              <router-link
                :to="{
                  name: RouteName.ADMIN_PROFILE,
                  params: { id: report.reporter.id },
                }"
              >
                <img
                  v-if="report.reporter.avatar"
                  class="image"
                  :src="report.reporter.avatar.url"
                  alt=""
                />
                {{ displayNameAndUsername(report.reporter) }}
              </router-link>
            </td>
          </tr>
          <tr>
            <td>{{ t("Reported") }}</td>
            <td>{{ formatDateTimeString(report.insertedAt) }}</td>
          </tr>
          <tr v-if="report.updatedAt !== report.insertedAt">
            <td>{{ t("Updated") }}</td>
            <td>{{ formatDateTimeString(report.updatedAt) }}</td>
          </tr>
          <tr>
            <td>{{ t("Status") }}</td>
            <td>
              <span v-if="report.status === ReportStatusEnum.OPEN">{{
                t("Open")
              }}</span>
              <span v-else-if="report.status === ReportStatusEnum.CLOSED">
                {{ t("Closed") }}
              </span>
              <span v-else-if="report.status === ReportStatusEnum.RESOLVED">
                {{ t("Resolved") }}
              </span>
              <span v-else>{{ t("Unknown") }}</span>
            </td>
          </tr>
        </tbody>
      </table>
    </section>

    <section class="bg-white dark:bg-zinc-700 rounded px-2 pt-1 pb-2 my-3">
      <h2 class="mb-1">{{ t("Report reason") }}</h2>
      <div class="">
        <div class="flex gap-1">
          <figure class="" v-if="report.reported.avatar">
            <img
              alt=""
              :src="report.reported.avatar.url"
              class="rounded-full"
              width="36"
              height="36"
            />
          </figure>
          <AccountCircle v-else :size="36" />
          <div class="">
            <p class="" v-if="report.reported.name">
              {{ report.reported.name }}
            </p>
            <p class="">@{{ usernameWithDomain(report.reported) }}</p>
          </div>
        </div>
        <div
          class="prose dark:prose-invert"
          v-if="report.content"
          v-html="nl2br(report.content)"
        />
        <p v-else>{{ t("No comment") }}</p>
      </div>
    </section>

    <section
      class="bg-white dark:bg-zinc-700 rounded px-2 pt-1 pb-2 my-3"
      v-if="
        report.events &&
        report.events?.length > 0 &&
        report.comments.length === 0
      "
    >
      <h2 class="mb-1">{{ t("Reported content") }}</h2>
      <ul>
        <li v-for="event in report.events" :key="event.id">
          <EventCard :event="event" mode="row" class="my-2 max-w-4xl" />
          <o-button
            variant="danger"
            @click="confirmEventDelete(event)"
            icon-left="delete"
            ><template v-if="isOnlyReportedContent">{{
              t("Delete event and resolve report")
            }}</template
            ><template v-else>{{ t("Delete event") }}</template></o-button
          >
        </li>
      </ul>
    </section>

    <section
      class="bg-white dark:bg-zinc-700 rounded px-2 pt-1 pb-2 my-3"
      v-if="report.comments.length > 0"
    >
      <h2 class="mb-1">{{ t("Reported content") }}</h2>
      <ul v-for="comment in report.comments" :key="comment.id">
        <li>
          <i18n-t keypath="Comment under event {eventTitle}" tag="p">
            <template #eventTitle>
              <router-link
                :to="{
                  name: RouteName.EVENT,
                  params: { uuid: comment.event?.uuid },
                }"
              >
                <b>{{ comment.event?.title }}</b>
              </router-link>
            </template>
          </i18n-t>
          <EventComment
            :root-comment="true"
            :comment="comment"
            :event="comment.event as IEvent"
            :current-actor="currentActor as IPerson"
            :readOnly="true"
          />
          <o-button
            v-if="!comment.deletedAt"
            variant="danger"
            @click="confirmCommentDelete(comment)"
            icon-left="delete"
            ><template v-if="isOnlyReportedContent">{{
              t("Delete comment and resolve report")
            }}</template
            ><template v-else>{{ t("Delete comment") }}</template></o-button
          >
        </li>
      </ul>
    </section>

    <section
      class="bg-white dark:bg-zinc-700 rounded px-2 pt-1 pb-2 my-3"
      v-if="
        report.events &&
        report.events?.length === 0 &&
        report.comments.length === 0
      "
    >
      <EmptyContent inline center icon="alert-circle">
        {{ t("No content found") }}
        <template #desc>
          {{ t("Maybe the content was removed by the author or a moderator") }}
        </template>
      </EmptyContent>
    </section>

    <section class="bg-white dark:bg-zinc-700 rounded px-2 pt-1 pb-2 my-3">
      <h2 class="mb-1">{{ t("Notes") }}</h2>
      <div
        class=""
        v-for="note in report.notes"
        :id="`note-${note.id}`"
        :key="note.id"
      >
        <p>{{ note.content }}</p>
        <router-link
          :to="{
            name: RouteName.ADMIN_PROFILE,
            params: { id: note.moderator.id },
          }"
        >
          <img
            alt=""
            class="rounded-full"
            :src="note.moderator.avatar.url"
            v-if="note.moderator.avatar"
          />
          @{{ note.moderator.preferredUsername }}
        </router-link>
        <br />
        <small>
          <a :href="`#note-${note.id}`" v-if="note.insertedAt">
            {{ formatDateTimeString(note.insertedAt) }}
          </a>
        </small>
      </div>

      <form
        @submit="
          createReportNoteMutation({
            reportId: report?.id,
            content: noteContent,
          })
        "
      >
        <o-field :label="t('New note')" label-for="newNoteInput">
          <o-input
            type="textarea"
            v-model="noteContent"
            id="newNoteInput"
          ></o-input>
        </o-field>
        <o-button class="mt-2" type="submit">{{ t("Add a note") }}</o-button>
      </form>
    </section>
  </div>
</template>
<script lang="ts" setup>
import { CREATE_REPORT_NOTE, REPORT, UPDATE_REPORT } from "@/graphql/report";
import { IReport, IReportNote } from "@/types/report.model";
import {
  IPerson,
  displayNameAndUsername,
  usernameWithDomain,
} from "@/types/actor";
import { DELETE_EVENT } from "@/graphql/event";
import uniq from "lodash/uniq";
import { nl2br } from "@/utils/html";
import { DELETE_COMMENT } from "@/graphql/comment";
import { IComment } from "@/types/comment.model";
import { ActorType, AntiSpamFeedback, ReportStatusEnum } from "@/types/enums";
import RouteName from "@/router/name";
import { GraphQLError } from "graphql";
import { ApolloCache, FetchResult } from "@apollo/client/core";
import { useLazyQuery, useMutation, useQuery } from "@vue/apollo-composable";
import { useCurrentActorClient } from "@/composition/apollo/actor";
import { useHead } from "@vueuse/head";
import { useI18n } from "vue-i18n";
import { useRouter } from "vue-router";
import { ref, computed, inject } from "vue";
import { formatDateTimeString } from "@/filters/datetime";
import AccountCircle from "vue-material-design-icons/AccountCircle.vue";
import { Dialog } from "@/plugins/dialog";
import { Notifier } from "@/plugins/notifier";
import EventCard from "@/components/Event/EventCard.vue";
import { useFeatures } from "@/composition/apollo/config";
import { IEvent } from "@/types/event.model";
import EmptyContent from "@/components/Utils/EmptyContent.vue";
import EventComment from "@/components/Comment/EventComment.vue";
import { SUSPEND_PROFILE } from "@/graphql/actor";
import { GET_USER, SUSPEND_USER } from "@/graphql/user";
import { IUser } from "@/types/current-user.model";
import { waitApolloQuery } from "@/vue-apollo";

const router = useRouter();

const props = defineProps<{ reportId: string }>();

const { currentActor } = useCurrentActorClient();

const { features } = useFeatures();

const antispamEnabled = computed(() => features.value?.antispam);

const { result: reportResult, onError: onReportQueryError } = useQuery<{
  report: IReport;
}>(REPORT, () => ({
  id: props.reportId,
}));

const report = computed(() => reportResult.value?.report);

onReportQueryError(({ graphQLErrors }) => {
  errors.value = uniq(
    graphQLErrors.map(({ message }: GraphQLError) => message)
  );
});

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => t("Report")),
});

const notifier = inject<Notifier>("notifier");

const errors = ref<string[]>([]);

const noteContent = ref("");

const reportedContent = computed(() => {
  return [...(report.value?.events ?? []), ...(report.value?.comments ?? [])];
});

const isOnlyReportedContent = computed(
  () => reportedContent.value.length === 1
);

const {
  mutate: createReportNoteMutation,
  onDone: createReportNoteMutationDone,
  onError: createReportNoteMutationError,
} = useMutation<{
  createReportNote: IReportNote;
}>(CREATE_REPORT_NOTE, () => ({
  update: (
    store: ApolloCache<{ createReportNote: IReportNote }>,
    { data }: FetchResult
  ) => {
    if (data == null) return;
    const cachedData = store.readQuery<{ report: IReport }>({
      query: REPORT,
      variables: { id: report.value?.id },
    });
    if (cachedData == null) return;
    const { report: cachedReport } = cachedData;
    if (cachedReport === null) {
      console.error("Cannot update event notes cache, because of null value.");
      return;
    }
    const note = data.createReportNote;
    note.moderator = currentActor.value;

    cachedReport.notes = cachedReport.notes.concat([note]);

    store.writeQuery({
      query: REPORT,
      variables: { id: report.value?.id },
      data: { report },
    });
  },
}));

createReportNoteMutationDone(() => {
  noteContent.value = "";
});

createReportNoteMutationError((error) => {
  console.error(error);
});

const dialog = inject<Dialog>("dialog");

const addResolveReportPart = computed(() => {
  if (isOnlyReportedContent.value) {
    return "<p>" + t("This will also resolve the report.") + "</p>";
  }
  return "";
});

const confirmEventDelete = (event: IEvent): void => {
  dialog?.confirm({
    title: t("Deleting event"),
    message:
      t(
        "Are you sure you want to <b>delete</b> this event? <b>This action cannot be undone</b>. You may want to engage the discussion with the event creator and ask them to edit their event instead."
      ) + addResolveReportPart.value,
    confirmText: isOnlyReportedContent.value
      ? t("Delete event and resolve report")
      : t("Delete event"),
    variant: "danger",
    hasIcon: true,
    onConfirm: () => deleteEvent(event),
  });
};

const confirmCommentDelete = (comment: IComment): void => {
  dialog?.confirm({
    title: t("Deleting comment"),
    message:
      t(
        "Are you sure you want to <b>delete</b> this comment? <b>This action cannot be undone</b>."
      ) + addResolveReportPart.value,
    confirmText: isOnlyReportedContent.value
      ? t("Delete comment and resolve report")
      : t("Delete comment"),
    variant: "danger",
    hasIcon: true,
    onConfirm: () => deleteCommentMutation({ commentId: comment.id }),
  });
};

const {
  mutate: deleteEventMutation,
  onDone: deleteEventMutationDone,
  onError: deleteEventMutationError,
} = useMutation<{ deleteEvent: { id: string } }>(DELETE_EVENT, () => ({
  update: (
    store: ApolloCache<{ deleteEvent: { id: string } }>,
    { data }: FetchResult
  ) => {
    if (data == null) return;
    const reportCachedData = store.readQuery<{ report: IReport }>({
      query: REPORT,
      variables: { id: report.value?.id },
    });
    if (reportCachedData == null) return;
    const { report: cachedReport } = reportCachedData;
    if (cachedReport === null) {
      console.error(
        "Cannot update report events cache, because of null value."
      );
      return;
    }
    const updatedReport = {
      ...cachedReport,
      events: cachedReport.events?.filter(
        (cachedEvent) => cachedEvent.id !== data.deleteEvent.id
      ),
    };

    store.writeQuery({
      query: REPORT,
      variables: { id: report.value?.id },
      data: { report: updatedReport },
    });
  },
}));

deleteEventMutationDone(async () => {
  if (reportedContent.value.length === 0) {
    await updateReport(ReportStatusEnum.RESOLVED);
    notifier?.success(t("Event deleted and report resolved"));
  } else {
    notifier?.success(t("Event deleted"));
  }
});

deleteEventMutationError((error) => {
  console.error(error);
});

const deleteEvent = async (event: IEvent): Promise<void> => {
  if (!event?.id) return;

  deleteEventMutation(
    { eventId: event.id },
    { context: { eventTitle: event.title } }
  );
};

const {
  mutate: deleteCommentMutation,
  onDone: deleteCommentMutationDone,
  onError: deleteCommentMutationError,
} = useMutation<{ deleteComment: { id: string } }>(DELETE_COMMENT, () => ({
  update: (
    store: ApolloCache<{ deleteComment: { id: string } }>,
    { data }: FetchResult
  ) => {
    if (data == null) return;
    const reportCachedData = store.readQuery<{ report: IReport }>({
      query: REPORT,
      variables: { id: report.value?.id },
    });
    if (reportCachedData == null) return;
    const { report: cachedReport } = reportCachedData;
    if (cachedReport === null) {
      console.error(
        "Cannot update report comments cache, because of null value."
      );
      return;
    }
    const updatedReport = {
      ...cachedReport,
      comments: cachedReport.comments.filter(
        (cachedComment) => cachedComment.id !== data.deleteComment.id
      ),
    };

    store.writeQuery({
      query: REPORT,
      variables: { id: report.value?.id },
      data: { report: updatedReport },
    });
  },
}));

deleteCommentMutationDone(async () => {
  if (reportedContent.value.length === 0) {
    await updateReport(ReportStatusEnum.RESOLVED);
    notifier?.success(t("Comment deleted and report resolved"));
  } else {
    notifier?.success(t("Comment deleted"));
  }
});

deleteCommentMutationError((error) => {
  console.error(error);
});

const {
  mutate: updateReportMutation,
  onDone: onUpdateReportMutation,
  onError: onUpdateReportError,
} = useMutation<
  Record<string, any>,
  {
    reportId: string;
    status: ReportStatusEnum;
    antispamFeedback?: AntiSpamFeedback;
  }
>(UPDATE_REPORT, () => ({
  update: (
    store: ApolloCache<{ updateReportStatus: IReport }>,
    { data }: FetchResult
  ) => {
    if (data == null) return;
    const reportCachedData = store.readQuery<{ report: IReport }>({
      query: REPORT,
      variables: { id: report.value?.id },
    });
    if (reportCachedData == null) return;
    const { report: cachedReport } = reportCachedData;
    if (cachedReport === null) {
      console.error("Cannot update event notes cache, because of null value.");
      return;
    }
    const updatedReport = {
      ...cachedReport,
      status: data.updateReportStatus.status,
    };

    store.writeQuery({
      query: REPORT,
      variables: { id: report.value?.id },
      data: { report: updatedReport },
    });
  },
}));

onUpdateReportMutation(async () => {
  await router.push({ name: RouteName.REPORTS });
});

onUpdateReportError((error) => {
  console.error(error);
});

const updateReport = async (status: ReportStatusEnum): Promise<void> => {
  if (report.value) {
    updateReportMutation({
      reportId: report.value?.id,
      status,
    });
  }
};

const reportToAntispam = (spam: boolean) => {
  dialog?.confirm({
    title: spam ? t("Report as undetected spam") : t("Report as ham"),
    message: t(
      "The report contents (eventual comments and event) and the reported profile details will be transmitted to Akismet."
    ),
    confirmText: t("Submit to Akismet"),
    variant: "warning",
    hasIcon: true,
    onConfirm: () => {
      if (report.value) {
        updateReportMutation({
          reportId: report.value.id,
          status: report.value.status,
          antispamFeedback: spam ? AntiSpamFeedback.SPAM : AntiSpamFeedback.HAM,
        });
      }
    },
  });
};

const { mutate: doSuspendProfile, onDone: onSuspendProfileDone } = useMutation<
  {
    suspendProfile: { id: string };
  },
  { id: string }
>(SUSPEND_PROFILE);

const { mutate: doSuspendUser, onDone: onSuspendUserDone } = useMutation<
  { suspendProfile: { id: string } },
  { userId: string }
>(SUSPEND_USER);

const userLazyQuery = useLazyQuery<{ user: IUser }, { id: string }>(GET_USER);

const suspendProfile = async (actorId: string): Promise<void> => {
  dialog?.confirm({
    title: t("Suspend the profile?"),
    message:
      t(
        "Do you really want to suspend this profile? All of the profiles content will be deleted."
      ) +
      `<p><b>` +
      t("There will be no way to restore the profile's data!") +
      `</b></p>`,
    confirmText: t("Suspend the profile"),
    cancelText: t("Cancel"),
    variant: "danger",
    onConfirm: async () => {
      doSuspendProfile({
        id: actorId,
      });
      return router.push({ name: RouteName.USERS });
    },
  });
};

const userSuspendedProfilesMessages = (user: IUser) => {
  return (
    t("The following user's profiles will be deleted, with all their data:") +
    `<ul class="list-disc pl-3">` +
    user.actors
      .map((person) => `<li>${displayNameAndUsername(person)}</li>`)
      .join("") +
    `</ul><b>`
  );
};

const cachedReportedUser = ref<IUser | undefined>();

const suspendUser = async (user: IUser): Promise<void> => {
  try {
    if (!cachedReportedUser.value) {
      userLazyQuery.load(GET_USER, { id: user.id });

      const userLazyQueryResult = await waitApolloQuery<
        { user: IUser },
        { id: string }
      >(userLazyQuery);
      console.debug("data", userLazyQueryResult);

      cachedReportedUser.value = userLazyQueryResult.data.user;
    }

    dialog?.confirm({
      title: t("Suspend the account?"),
      message:
        t("Do you really want to suspend the account « {emailAccount} » ?", {
          emailAccount: cachedReportedUser.value.email,
        }) +
        " " +
        userSuspendedProfilesMessages(cachedReportedUser.value) +
        "<b>" +
        t("There will be no way to restore the user's data!") +
        `</b>`,
      confirmText: t("Suspend the account"),
      cancelText: t("Cancel"),
      variant: "danger",
      onConfirm: async () => {
        doSuspendUser({
          userId: user.id,
        });
        return router.push({ name: RouteName.USERS });
      },
    });
  } catch (e) {
    console.error(e);
  }
};

onSuspendUserDone(async () => {
  await router.push({ name: RouteName.REPORTS });
  notifier?.success(t("User suspended and report resolved"));
});

onSuspendProfileDone(async () => {
  await router.push({ name: RouteName.REPORTS });
  notifier?.success(t("Profile suspended and report resolved"));
});
</script>
<style lang="scss" scoped>
tbody td img.image,
.note img.image {
  display: inline;
  height: 1.5em;
  vertical-align: text-bottom;
}

.dialog .modal-card-foot {
  justify-content: flex-end;
}

.box a {
  text-decoration: none;
  color: inherit;
}
</style>
