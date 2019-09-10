<template>
    <section class="container">
        <b-message title="Error" type="is-danger" v-for="error in errors" :key="error">{{ error }}</b-message>
        <div class="container" v-if="report">
            <nav class="breadcrumb" aria-label="breadcrumbs">
                <ul>
                    <li><router-link :to="{ name: AdminRouteName.DASHBOARD }">Dashboard</router-link></li>
                    <li><router-link :to="{ name: ModerationRouteName.REPORTS }">Reports</router-link></li>
                    <li class="is-active"><router-link :to="{ name: ModerationRouteName.REPORT, params: { reportId: this.report.id} }" aria-current="page">Report</router-link></li>
                </ul>
            </nav>
            <div class="buttons">
                <b-button v-if="report.status !== ReportStatusEnum.RESOLVED" @click="updateReport(ReportStatusEnum.RESOLVED)" type="is-primary">Mark as resolved</b-button>
                <b-button v-if="report.status !== ReportStatusEnum.OPEN" @click="updateReport(ReportStatusEnum.OPEN)" type="is-success">Reopen</b-button>
                <b-button v-if="report.status !== ReportStatusEnum.CLOSED" @click="updateReport(ReportStatusEnum.CLOSED)" type="is-danger">Close</b-button>
            </div>
            <div class="columns">
                <div class="column">
                    <div class="table-container">
                        <table class="box table is-striped">
                            <tbody>
                                <tr>
                                    <td>Compte signalé</td>
                                    <td>
                                        <router-link :to="{ name: ActorRouteName.PROFILE, params: { name: report.reported.preferredUsername } }">
                                            <img v-if="report.reported.avatar" class="image" :src="report.reported.avatar.url" /> @{{ report.reported.preferredUsername }}
                                        </router-link>
                                    </td>
                                </tr>
                                <tr>
                                    <td>Signalé par</td>
                                    <td>
                                        <router-link :to="{ name: ActorRouteName.PROFILE, params: { name: report.reporter.preferredUsername } }">
                                            <img v-if="report.reporter.avatar" class="image" :src="report.reporter.avatar.url" /> @{{ report.reporter.preferredUsername }}
                                        </router-link>
                                    </td>
                                </tr>
                                <tr>
                                    <td>Signalé</td>
                                    <td>{{ report.insertedAt | formatDateTimeString }}</td>
                                </tr>
                                <tr v-if="report.updatedAt !== report.insertedAt">
                                    <td>Mis à jour</td>
                                    <td>{{ report.updatedAt | formatDateTimeString }}</td>
                                </tr>
                                <tr>
                                    <td>Statut</td>
                                    <td>
                                        <span v-if="report.status === ReportStatusEnum.OPEN">Ouvert</span>
                                        <span v-else-if="report.status === ReportStatusEnum.CLOSED">Fermé</span>
                                        <span v-else-if="report.status === ReportStatusEnum.RESOLVED">Résolu</span>
                                        <span v-else>Inconnu</span>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>

                <div class="column">
                    <div class="box">
                        <p v-if="report.content">{{ report.content }}</p>
                        <p v-else>Pas de commentaire</p>
                    </div>
                </div>
            </div>

            <div class="box" v-if="report.event">
                <router-link :to="{ name: EventRouteName.EVENT, params: { uuid: report.event.uuid }}">
                    <h3 class="title">{{ report.event.title }}</h3>
                    <p v-html="report.event.description"></p>
                </router-link>
                <b-button
                        tag="router-link"
                        type="is-primary"
                        :to="{ name: EventRouteName.EDIT_EVENT, params: {eventId: report.event.uuid } }"
                        icon-left="pencil"
                        size="is-small">Edit</b-button>
                <b-button
                        type="is-danger"
                        @click="confirmDelete()"
                        icon-left="delete"
                        size="is-small">Delete</b-button>
            </div>

            <h2 class="title" v-if="report.notes.length > 0">Notes</h2>
            <div class="box note" v-for="note in report.notes" :id="`note-${note.id}`">
                <p>{{ note.content }}</p>
                <router-link :to="{ name: ActorRouteName.PROFILE, params: { name: note.moderator.preferredUsername } }">
                    <img class="image" :src="note.moderator.avatar.url" /> @{{ note.moderator.preferredUsername }}
                </router-link><br />
                <small><a :href="`#note-${note.id}`" v-if="note.insertedAt">{{ note.insertedAt | formatDateTimeString }}</a></small>
            </div>

            <form @submit="addNote()">
                <b-field label="Nouvelle note">
                    <b-input type="textarea" v-model="noteContent"></b-input>
                </b-field>
                <b-button type="submit" @click="addNote">Ajouter une note</b-button>
            </form>
        </div>
    </section>
</template>
<script lang="ts">
import { Component, Prop, Vue } from 'vue-property-decorator';
import { CREATE_REPORT_NOTE, REPORT, REPORTS, UPDATE_REPORT } from '@/graphql/report';
import { IReport, IReportNote, ReportStatusEnum } from '@/types/report.model';
import { EventRouteName } from '@/router/event';
import { ActorRouteName } from '@/router/actor';
import { AdminRouteName } from '@/router/admin';
import { ModerationRouteName } from '@/router/moderation';
import { LOGGED_PERSON } from '@/graphql/actor';
import { IPerson } from '@/types/actor';
import { DELETE_EVENT } from '@/graphql/event';
import { uniq } from 'lodash';

@Component({
  apollo: {
    report: {
      query: REPORT,
      variables() {
        return {
          id: this.reportId,
        };
      },
      error({ graphQLErrors }) {
        this.errors = uniq(graphQLErrors.map(({ message }) => message));
      },
    },
    loggedPerson: {
      query: LOGGED_PERSON,
    },
  },
})
export default class Report extends Vue {
  @Prop({ required: true }) reportId!: number;
  report!: IReport;
  loggedPerson!: IPerson;
  errors: string[] = [];

  ReportStatusEnum = ReportStatusEnum;
  EventRouteName = EventRouteName;
  ActorRouteName = ActorRouteName;
  AdminRouteName = AdminRouteName;
  ModerationRouteName = ModerationRouteName;

  noteContent: string = '';

  addNote() {
    try {
      this.$apollo.mutate<{ createReportNote: IReportNote }>({
        mutation: CREATE_REPORT_NOTE,
        variables: {
          reportId: this.report.id,
          moderatorId: this.loggedPerson.id,
          content: this.noteContent,
        },
        update: (store, { data }) => {
          if (data == null) return;
          const cachedData = store.readQuery<{ report: IReport }>({ query: REPORT, variables: { id: this.report.id } });
          if (cachedData == null) return;
          const { report } = cachedData;
          if (report === null) {
            console.error('Cannot update event notes cache, because of null value.');
            return;
          }
          const note = data.createReportNote;
          note.moderator = this.loggedPerson;

          report.notes = report.notes.concat([note]);

          store.writeQuery({ query: REPORT, data: { report } });
        },
      });

      this.noteContent = '';
    } catch (error) {
      console.error(error);
    }
  }

  confirmDelete() {
    this.$buefy.dialog.confirm({
      title: 'Deleting event',
      message: 'Are you sure you want to <b>delete</b> this event? This action cannot be undone. You may want to engage the conversation with the event creator or edit its event instead.',
      confirmText: 'Delete Event',
      type: 'is-danger',
      hasIcon: true,
      onConfirm: () => this.deleteEvent(),
    });
  }

  async deleteEvent() {
    if (!this.report.event || !this.report.event.id) return;
    const eventTitle = this.report.event.title;

    try {
      await this.$apollo.mutate({
        mutation: DELETE_EVENT,
        variables: {
          eventId: this.report.event.id.toString(),
          actorId: this.loggedPerson.id,
        },
      });

      this.$buefy.notification.open({
        message: this.$gettextInterpolate('Event %{eventTitle} deleted', { eventTitle }),
        type: 'is-success',
        position: 'is-bottom-right',
        duration: 5000,
      });
    } catch (error) {
      console.error(error);
    }
  }

  async updateReport(status: ReportStatusEnum) {
    try {
      await this.$apollo.mutate({
        mutation: UPDATE_REPORT,
        variables: {
          reportId: this.report.id,
          moderatorId: this.loggedPerson.id,
          status,
        },
        update: (store, { data }) => {
          if (data == null) return;
          const reportCachedData = store.readQuery<{ report: IReport }>({ query: REPORT, variables: { id: this.report.id } });
          if (reportCachedData == null) return;
          const { report } = reportCachedData;
          if (report === null) {
            console.error('Cannot update event notes cache, because of null value.');
            return;
          }
          const updatedReport = data.updateReportStatus;
          report.status = updatedReport.status;

          store.writeQuery({ query: REPORT, data: { report } });
        },
      });
    } catch (error) {
      console.error(error);
    }
  }

    // TODO make me a global function
  formatDate(value) {
    return value ? new Date(value).toLocaleString(undefined, { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' }) : null;
  }

  formatTime(value) {
    return value ? new Date(value).toLocaleTimeString(undefined, { hour: 'numeric', minute: 'numeric' }) : null;
  }

}
</script>
<style lang="scss">
    .container li {
        margin: 10px auto;
    }

    tbody td img.image, .note img.image {
        display: inline;
        height: 1.5em;
        vertical-align: text-bottom;
    }

    .dialog .modal-card-foot {
        justify-content: flex-end;
    }
</style>