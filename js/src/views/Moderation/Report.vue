<template>
  <div>
    <nav class="breadcrumb" aria-label="breadcrumbs" v-if="report">
      <ul>
        <li>
          <router-link :to="{ name: RouteName.MODERATION }">{{
            $t("Moderation")
          }}</router-link>
        </li>
        <li>
          <router-link :to="{ name: RouteName.REPORTS }">{{
            $t("Reports")
          }}</router-link>
        </li>
        <li class="is-active">
          <router-link
            :to="{ name: RouteName.REPORT, params: { id: report.id } }"
            >{{
              $t("Report #{reportNumber}", { reportNumber: report.id })
            }}</router-link
          >
        </li>
      </ul>
    </nav>
    <section>
      <b-message
        title="Error"
        type="is-danger"
        v-for="error in errors"
        :key="error"
      >
        {{ error }}
      </b-message>
      <div class="container" v-if="report">
        <div class="buttons">
          <b-button
            v-if="report.status !== ReportStatusEnum.RESOLVED"
            @click="updateReport(ReportStatusEnum.RESOLVED)"
            type="is-primary"
            >{{ $t("Mark as resolved") }}</b-button
          >
          <b-button
            v-if="report.status !== ReportStatusEnum.OPEN"
            @click="updateReport(ReportStatusEnum.OPEN)"
            type="is-success"
            >{{ $t("Reopen") }}</b-button
          >
          <b-button
            v-if="report.status !== ReportStatusEnum.CLOSED"
            @click="updateReport(ReportStatusEnum.CLOSED)"
            type="is-danger"
            >{{ $t("Close") }}</b-button
          >
        </div>
        <div class="table-container">
          <table class="table is-striped is-fullwidth">
            <tbody>
              <tr v-if="report.reported.__typename === 'Group'">
                <td>{{ $t("Reported group") }}</td>
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
                  {{ $t("Reported identity") }}
                </td>
                <td>
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
                </td>
              </tr>
              <tr>
                <td>{{ $t("Reported by") }}</td>
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
                <td>{{ $t("Reported") }}</td>
                <td>{{ report.insertedAt | formatDateTimeString }}</td>
              </tr>
              <tr v-if="report.updatedAt !== report.insertedAt">
                <td>{{ $t("Updated") }}</td>
                <td>{{ report.updatedAt | formatDateTimeString }}</td>
              </tr>
              <tr>
                <td>{{ $t("Status") }}</td>
                <td>
                  <span v-if="report.status === ReportStatusEnum.OPEN">{{
                    $t("Open")
                  }}</span>
                  <span v-else-if="report.status === ReportStatusEnum.CLOSED">
                    {{ $t("Closed") }}
                  </span>
                  <span v-else-if="report.status === ReportStatusEnum.RESOLVED">
                    {{ $t("Resolved") }}
                  </span>
                  <span v-else>{{ $t("Unknown") }}</span>
                </td>
              </tr>
              <tr v-if="report.event && report.comments.length > 0">
                <td>{{ $t("Event") }}</td>
                <td>
                  <router-link
                    :to="{
                      name: RouteName.EVENT,
                      params: { uuid: report.event.uuid },
                    }"
                  >
                    {{ report.event.title }}
                  </router-link>
                  <span class="is-pulled-right">
                    <!--                                    <b-button-->
                    <!--                                            tag="router-link"-->
                    <!--                                            type="is-primary"-->
                    <!--                                            :to="{ name: RouteName.EDIT_EVENT, params: {eventId: report.event.uuid } }"-->
                    <!--                                            icon-left="pencil"-->
                    <!--                                            size="is-small">{{ $t('Edit') }}</b-button>-->
                    <b-button
                      type="is-danger"
                      @click="confirmEventDelete()"
                      icon-left="delete"
                      size="is-small"
                      >{{ $t("Delete") }}</b-button
                    >
                  </span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="box report-content">
          <p v-if="report.content" v-html="nl2br(report.content)" />
          <p v-else>{{ $t("No comment") }}</p>
        </div>

        <div class="box" v-if="report.event && report.comments.length === 0">
          <router-link
            :to="{ name: RouteName.EVENT, params: { uuid: report.event.uuid } }"
          >
            <h3 class="title">{{ report.event.title }}</h3>
            <p v-html="report.event.description" />
          </router-link>
          <!--                <b-button-->
          <!--                        tag="router-link"-->
          <!--                        type="is-primary"-->
          <!--                        :to="{ name: RouteName.EDIT_EVENT, params: {eventId: report.event.uuid } }"-->
          <!--                        icon-left="pencil"-->
          <!--                        size="is-small">{{ $t('Edit') }}</b-button>-->
          <b-button
            type="is-danger"
            @click="confirmEventDelete()"
            icon-left="delete"
            size="is-small"
            >{{ $t("Delete") }}</b-button
          >
        </div>

        <div v-if="report.comments.length > 0">
          <ul v-for="comment in report.comments" :key="comment.id">
            <li>
              <div class="box" v-if="comment">
                <article class="media">
                  <div class="media-left">
                    <figure
                      class="image is-48x48"
                      v-if="comment.actor && comment.actor.avatar"
                    >
                      <img :src="comment.actor.avatar.url" alt="Image" />
                    </figure>
                    <b-icon
                      class="media-left"
                      v-else
                      size="is-large"
                      icon="account-circle"
                    />
                  </div>
                  <div class="media-content">
                    <div class="content">
                      <span v-if="comment.actor">
                        <strong>{{ comment.actor.name }}</strong>
                        <small>@{{ comment.actor.preferredUsername }}</small>
                      </span>
                      <span v-else>{{ $t("Unknown actor") }}</span>
                      <br />
                      <p v-html="comment.text" />
                    </div>
                    <b-button
                      type="is-danger"
                      @click="confirmCommentDelete(comment)"
                      icon-left="delete"
                      size="is-small"
                      >{{ $t("Delete") }}</b-button
                    >
                  </div>
                </article>
              </div>
            </li>
          </ul>
        </div>

        <h2 class="title" v-if="report.notes.length > 0">{{ $t("Notes") }}</h2>
        <div
          class="box note"
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
              alt
              class="image"
              :src="note.moderator.avatar.url"
              v-if="note.moderator.avatar"
            />
            @{{ note.moderator.preferredUsername }}
          </router-link>
          <br />
          <small>
            <a :href="`#note-${note.id}`" v-if="note.insertedAt">
              {{ note.insertedAt | formatDateTimeString }}
            </a>
          </small>
        </div>

        <form @submit="addNote()">
          <b-field :label="$t('New note')" label-for="newNoteInput">
            <b-input
              type="textarea"
              v-model="noteContent"
              id="newNoteInput"
            ></b-input>
          </b-field>
          <b-button type="submit" @click="addNote">{{
            $t("Add a note")
          }}</b-button>
        </form>
      </div>
    </section>
  </div>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { CREATE_REPORT_NOTE, REPORT, UPDATE_REPORT } from "@/graphql/report";
import { IReport, IReportNote } from "@/types/report.model";
import { CURRENT_ACTOR_CLIENT } from "@/graphql/actor";
import { IPerson, displayNameAndUsername } from "@/types/actor";
import { DELETE_EVENT } from "@/graphql/event";
import { uniq } from "lodash";
import { nl2br } from "@/utils/html";
import { DELETE_COMMENT } from "@/graphql/comment";
import { IComment } from "@/types/comment.model";
import { ActorType, ReportStatusEnum } from "@/types/enums";
import RouteName from "../../router/name";

@Component({
  apollo: {
    report: {
      query: REPORT,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          id: this.reportId,
        };
      },
      error({ graphQLErrors }) {
        this.errors = uniq(graphQLErrors.map(({ message }) => message));
      },
    },
    currentActor: {
      query: CURRENT_ACTOR_CLIENT,
    },
  },
  metaInfo() {
    return {
      title: this.$t("Report") as string,
      titleTemplate: "%s | Mobilizon",
    };
  },
})
export default class Report extends Vue {
  @Prop({ required: true }) reportId!: number;

  report!: IReport;

  currentActor!: IPerson;

  errors: string[] = [];

  ReportStatusEnum = ReportStatusEnum;

  RouteName = RouteName;

  ActorType = ActorType;

  nl2br = nl2br;

  noteContent = "";

  displayNameAndUsername = displayNameAndUsername;

  addNote(): void {
    try {
      this.$apollo.mutate<{ createReportNote: IReportNote }>({
        mutation: CREATE_REPORT_NOTE,
        variables: {
          reportId: this.report.id,
          content: this.noteContent,
        },
        update: (store, { data }) => {
          if (data == null) return;
          const cachedData = store.readQuery<{ report: IReport }>({
            query: REPORT,
            variables: { id: this.report.id },
          });
          if (cachedData == null) return;
          const { report } = cachedData;
          if (report === null) {
            console.error(
              "Cannot update event notes cache, because of null value."
            );
            return;
          }
          const note = data.createReportNote;
          note.moderator = this.currentActor;

          report.notes = report.notes.concat([note]);

          store.writeQuery({
            query: REPORT,
            variables: { id: this.report.id },
            data: { report },
          });
        },
      });

      this.noteContent = "";
    } catch (error) {
      console.error(error);
    }
  }

  confirmEventDelete(): void {
    this.$buefy.dialog.confirm({
      title: this.$t("Deleting event") as string,
      message: this.$t(
        "Are you sure you want to <b>delete</b> this event? This action cannot be undone. You may want to engage the discussion with the event creator or edit its event instead."
      ) as string,
      confirmText: this.$t("Delete Event") as string,
      type: "is-danger",
      hasIcon: true,
      onConfirm: () => this.deleteEvent(),
    });
  }

  confirmCommentDelete(comment: IComment): void {
    this.$buefy.dialog.confirm({
      title: this.$t("Deleting comment") as string,
      message: this.$t(
        "Are you sure you want to <b>delete</b> this comment? This action cannot be undone."
      ) as string,
      confirmText: this.$t("Delete Comment") as string,
      type: "is-danger",
      hasIcon: true,
      onConfirm: () => this.deleteComment(comment),
    });
  }

  async deleteEvent(): Promise<void> {
    if (!this.report.event || !this.report.event.id) return;
    const eventTitle = this.report.event.title;

    try {
      await this.$apollo.mutate({
        mutation: DELETE_EVENT,
        variables: {
          eventId: this.report.event.id.toString(),
        },
      });

      this.$buefy.notification.open({
        message: this.$t("Event {eventTitle} deleted", {
          eventTitle,
        }) as string,
        type: "is-success",
        position: "is-bottom-right",
        duration: 5000,
      });
    } catch (error) {
      console.error(error);
    }
  }

  async deleteComment(comment: IComment): Promise<void> {
    try {
      await this.$apollo.mutate({
        mutation: DELETE_COMMENT,
        variables: {
          commentId: comment.id,
        },
      });
      this.$notifier.success(this.$t("Comment deleted") as string);
    } catch (error) {
      console.error(error);
    }
  }

  async updateReport(status: ReportStatusEnum): Promise<void> {
    try {
      await this.$apollo.mutate({
        mutation: UPDATE_REPORT,
        variables: {
          reportId: this.report.id,
          status,
        },
        update: (store, { data }) => {
          if (data == null) return;
          const reportCachedData = store.readQuery<{ report: IReport }>({
            query: REPORT,
            variables: { id: this.report.id },
          });
          if (reportCachedData == null) return;
          const { report } = reportCachedData;
          if (report === null) {
            console.error(
              "Cannot update event notes cache, because of null value."
            );
            return;
          }
          const updatedReport = data.updateReportStatus;
          report.status = updatedReport.status;

          store.writeQuery({
            query: REPORT,
            variables: { id: this.report.id },
            data: { report },
          });
        },
      });
      await this.$router.push({ name: RouteName.REPORTS });
    } catch (error) {
      console.error(error);
    }
  }
}
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

.report-content {
  border-left: 4px solid $primary;
}

.box a {
  text-decoration: none;
  color: inherit;
}

td > a {
  text-decoration: none;
}
</style>
