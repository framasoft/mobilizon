<template>
  <div>
    <nav class="breadcrumb" aria-label="breadcrumbs">
      <ul>
        <li>
          <router-link :to="{ name: RouteName.IDENTITIES }">{{
            $t("Profiles")
          }}</router-link>
        </li>
        <li class="is-active" v-if="isUpdate && identity">
          <router-link
            :to="{
              name: RouteName.UPDATE_IDENTITY,
              params: { identityName: identity.preferredUsername },
            }"
            >{{ identity.name }}</router-link
          >
        </li>
        <li class="is-active" v-else>
          <router-link :to="{ name: RouteName.CREATE_IDENTITY }">{{
            $t("New profile")
          }}</router-link>
        </li>
      </ul>
    </nav>
    <div class="root" v-if="identity">
      <h1 class="title">
        <span v-if="isUpdate">{{ identity.displayName() }}</span>
        <span v-else>{{ $t("I create an identity") }}</span>
      </h1>

      <picture-upload
        v-model="avatarFile"
        :defaultImage="identity.avatar"
        :maxSize="avatarMaxSize"
        class="picture-upload"
      />

      <b-field horizontal :label="$t('Display name')">
        <b-input
          aria-required="true"
          required
          v-model="identity.name"
          @input="autoUpdateUsername($event)"
        />
      </b-field>

      <b-field
        horizontal
        custom-class="username-field"
        expanded
        :label="$t('Username')"
        :message="message"
      >
        <b-field expanded>
          <b-input
            aria-required="true"
            required
            v-model="identity.preferredUsername"
            :disabled="isUpdate"
            :use-html5-validation="!isUpdate"
            pattern="[a-z0-9_]+"
          />

          <p class="control">
            <span class="button is-static">@{{ getInstanceHost }}</span>
          </p>
        </b-field>
      </b-field>

      <b-field horizontal :label="$t('Description')">
        <b-input
          type="textarea"
          aria-required="false"
          v-model="identity.summary"
        />
      </b-field>

      <b-notification
        type="is-danger"
        has-icon
        aria-close-label="Close notification"
        role="alert"
        :key="error"
        v-for="error in errors"
        >{{ error }}</b-notification
      >

      <b-field class="submit">
        <div class="control">
          <button type="button" class="button is-primary" @click="submit()">
            {{ $t("Save") }}
          </button>
        </div>
      </b-field>

      <div class="delete-identity" v-if="isUpdate">
        <span @click="openDeleteIdentityConfirmation()">{{
          $t("Delete this identity")
        }}</span>
      </div>

      <section v-if="isUpdate">
        <div class="setting-title">
          <h2>{{ $t("Profile feeds") }}</h2>
        </div>
        <p>
          {{
            $t(
              "These feeds contain event data for the events for which this specific profile is a participant or creator. You should keep these private. You can find feeds for all of your profiles into your notification settings."
            )
          }}
        </p>
        <div v-if="identity.feedTokens && identity.feedTokens.length > 0">
          <div
            class="buttons"
            v-for="feedToken in identity.feedTokens"
            :key="feedToken.token"
          >
            <b-tooltip
              :label="$t('URL copied to clipboard')"
              :active="showCopiedTooltip.atom"
              always
              type="is-success"
              position="is-left"
            >
              <b-button
                tag="a"
                icon-left="rss"
                @click="
                  (e) => copyURL(e, tokenToURL(feedToken.token, 'atom'), 'atom')
                "
                :href="tokenToURL(feedToken.token, 'atom')"
                target="_blank"
                >{{ $t("RSS/Atom Feed") }}</b-button
              >
            </b-tooltip>
            <b-tooltip
              :label="$t('URL copied to clipboard')"
              :active="showCopiedTooltip.ics"
              always
              type="is-success"
              position="is-left"
            >
              <b-button
                tag="a"
                @click="
                  (e) => copyURL(e, tokenToURL(feedToken.token, 'ics'), 'ics')
                "
                icon-left="calendar-sync"
                :href="tokenToURL(feedToken.token, 'ics')"
                target="_blank"
                >{{ $t("ICS/WebCal Feed") }}</b-button
              >
            </b-tooltip>
            <b-button
              icon-left="refresh"
              type="is-text"
              @click="openRegenerateFeedTokensConfirmation"
              >{{ $t("Regenerate new links") }}</b-button
            >
          </div>
        </div>
        <div v-else>
          <b-button
            icon-left="refresh"
            type="is-text"
            @click="generateFeedTokens"
            >{{ $t("Create new links") }}</b-button
          >
        </div>
      </section>
    </div>
  </div>
</template>

<style scoped type="scss">
h1 {
  display: flex;
  justify-content: center;
}

.picture-upload {
  margin: 30px 0;
}

.submit,
.delete-identity {
  display: flex;
  justify-content: center;
}

.submit {
  margin: 30px 0;
}

.delete-identity {
  text-decoration: underline;
  cursor: pointer;
  margin-top: 15px;
}

.username-field + .field {
  margin-bottom: 0;
}

::v-deep .buttons > *:not(:last-child) .button {
  margin-right: 0.5rem;
}
</style>

<script lang="ts">
import { Component, Prop, Watch } from "vue-property-decorator";
import { mixins } from "vue-class-component";
import {
  CREATE_PERSON,
  CURRENT_ACTOR_CLIENT,
  DELETE_PERSON,
  FETCH_PERSON,
  IDENTITIES,
  UPDATE_PERSON,
} from "../../../graphql/actor";
import { IPerson, Person } from "../../../types/actor";
import PictureUpload from "../../../components/PictureUpload.vue";
import { MOBILIZON_INSTANCE_HOST } from "../../../api/_entrypoint";
import RouteName from "../../../router/name";
import { buildFileVariable } from "../../../utils/image";
import { changeIdentity } from "../../../utils/auth";
import identityEditionMixin from "../../../mixins/identityEdition";
import {
  CREATE_FEED_TOKEN_ACTOR,
  DELETE_FEED_TOKEN,
} from "@/graphql/feed_tokens";
import { IFeedToken } from "@/types/feedtoken.model";
import { ServerParseError } from "apollo-link-http-common";
import { IConfig } from "@/types/config.model";
import { CONFIG } from "@/graphql/config";

@Component({
  components: {
    PictureUpload,
  },
  apollo: {
    currentActor: {
      query: CURRENT_ACTOR_CLIENT,
    },
    identity: {
      query: FETCH_PERSON,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          username: this.identityName,
        };
      },
      skip() {
        return !this.identityName;
      },
      update: (data) => new Person(data.fetchPerson),
      error({ graphQLErrors }) {
        this.handleErrors(graphQLErrors);
      },
    },
    config: CONFIG,
  },
})
export default class EditIdentity extends mixins(identityEditionMixin) {
  @Prop({ type: Boolean }) isUpdate!: boolean;

  @Prop({ type: String }) identityName!: string;

  config!: IConfig;

  errors: string[] = [];

  avatarFile: File | null = null;

  private currentActor: IPerson | null = null;

  RouteName = RouteName;

  showCopiedTooltip = { ics: false, atom: false };

  get message(): string | null {
    if (this.isUpdate) return null;
    return this.$t(
      "Only alphanumeric lowercased characters and underscores are supported."
    ) as string;
  }

  @Watch("isUpdate")
  async isUpdateChanged(): Promise<void> {
    this.resetFields();
  }

  @Watch("identityName", { immediate: true })
  async onIdentityParamChanged(val: string): Promise<void> {
    // Only used when we update the identity
    if (!this.isUpdate) return;

    await this.redirectIfNoIdentitySelected(val);

    if (!this.identityName) {
      this.$router.push({ name: "CreateIdentity" });
    }

    if (this.identityName && this.identity) {
      this.avatarFile = null;
    }
  }

  submit(): Promise<void> {
    if (this.isUpdate) return this.updateIdentity();

    return this.createIdentity();
  }

  /**
   * Delete an identity
   */
  async deleteIdentity(): Promise<void> {
    try {
      await this.$apollo.mutate({
        mutation: DELETE_PERSON,
        variables: {
          id: this.identity.id,
        },
        update: (store) => {
          const data = store.readQuery<{ identities: IPerson[] }>({
            query: IDENTITIES,
          });

          if (data) {
            data.identities = data.identities.filter(
              (i) => i.id !== this.identity.id
            );

            store.writeQuery({ query: IDENTITIES, data });
          }
        },
      });

      this.$notifier.success(
        this.$t("Identity {displayName} deleted", {
          displayName: this.identity.displayName(),
        }) as string
      );
      /**
       * If we just deleted the current identity,
       * we need to change it to the next one
       */
      const data = this.$apollo.provider.defaultClient.readQuery<{
        identities: IPerson[];
      }>({ query: IDENTITIES });
      if (data) {
        await this.maybeUpdateCurrentActorCache(data.identities[0]);
      }

      await this.redirectIfNoIdentitySelected();
    } catch (err) {
      this.handleError(err);
    }
  }

  async updateIdentity(): Promise<void> {
    try {
      const variables = await this.buildVariables();

      await this.$apollo.mutate({
        mutation: UPDATE_PERSON,
        variables,
        update: (store, { data: { updatePerson } }) => {
          const data = store.readQuery<{ identities: IPerson[] }>({
            query: IDENTITIES,
          });

          if (data) {
            const index = data.identities.findIndex(
              (i) => i.id === this.identity.id
            );

            this.$set(data.identities, index, updatePerson);
            this.maybeUpdateCurrentActorCache(updatePerson);

            store.writeQuery({ query: IDENTITIES, data });
          }
        },
      });

      this.$notifier.success(
        this.$t("Identity {displayName} updated", {
          displayName: this.identity.displayName(),
        }) as string
      );
    } catch (err) {
      this.handleError(err);
    }
  }

  async createIdentity(): Promise<void> {
    try {
      const variables = await this.buildVariables();

      await this.$apollo.mutate({
        mutation: CREATE_PERSON,
        variables,
        update: (store, { data: { createPerson } }) => {
          const data = store.readQuery<{ identities: IPerson[] }>({
            query: IDENTITIES,
          });

          if (data) {
            data.identities.push(createPerson);

            store.writeQuery({ query: IDENTITIES, data });
          }
        },
      });

      this.$notifier.success(
        this.$t("Identity {displayName} created", {
          displayName: this.identity.displayName(),
        }) as string
      );

      await this.$router.push({
        name: RouteName.UPDATE_IDENTITY,
        params: { identityName: this.identity.preferredUsername },
      });
    } catch (err) {
      this.handleError(err);
    }
  }

  handleErrors(errors: any[]): void {
    if (errors.some((error) => error.status_code === 401)) {
      this.$router.push({ name: RouteName.LOGIN });
    }
  }

  // eslint-disable-next-line class-methods-use-this
  get getInstanceHost(): string {
    return MOBILIZON_INSTANCE_HOST;
  }

  tokenToURL(token: string, format: string): string {
    return `${window.location.origin}/events/going/${token}/${format}`;
  }

  copyURL(e: Event, url: string, format: "ics" | "atom"): void {
    if (navigator.clipboard) {
      e.preventDefault();
      navigator.clipboard.writeText(url);
      this.showCopiedTooltip[format] = true;
      setTimeout(() => {
        this.showCopiedTooltip[format] = false;
      }, 2000);
    }
  }

  get avatarMaxSize(): number | undefined {
    return this?.config?.uploadLimits?.avatar;
  }

  async generateFeedTokens(): Promise<void> {
    const newToken = await this.createNewFeedToken();
    this.identity.feedTokens.push(newToken);
  }

  async regenerateFeedTokens(): Promise<void> {
    if (this.identity?.feedTokens.length < 1) return;
    await this.deleteFeedToken(this.identity.feedTokens[0].token);
    const newToken = await this.createNewFeedToken();
    this.identity.feedTokens.pop();
    this.identity.feedTokens.push(newToken);
  }

  private async deleteFeedToken(token: string): Promise<void> {
    await this.$apollo.mutate({
      mutation: DELETE_FEED_TOKEN,
      variables: { token },
    });
  }

  private async createNewFeedToken(): Promise<IFeedToken> {
    const { data } = await this.$apollo.mutate({
      mutation: CREATE_FEED_TOKEN_ACTOR,
      variables: { actor_id: this.identity?.id },
    });

    return data.createFeedToken;
  }

  openRegenerateFeedTokensConfirmation(): void {
    this.$buefy.dialog.confirm({
      type: "is-warning",
      title: this.$t("Regenerate new links") as string,
      message: this.$t(
        "You'll need to change the URLs where there were previously entered."
      ) as string,
      confirmText: this.$t("Regenerate new links") as string,
      cancelText: this.$t("Cancel") as string,
      onConfirm: () => this.regenerateFeedTokens(),
    });
  }

  openDeleteIdentityConfirmation(): void {
    this.$buefy.dialog.prompt({
      type: "is-danger",
      title: this.$t("Delete your identity") as string,
      message: `${this.$t(
        "This will delete / anonymize all content (events, comments, messages, participations…) created from this identity."
      )}
            <br /><br />
            ${this.$t(
              "If this identity is the only administrator of some groups, you need to delete them before being able to delete this identity."
            )}
            ${this.$t(
              "Otherwise this identity will just be removed from the group administrators."
            )}
            <br /><br />
            ${this.$t(
              'To confirm, type your identity username "{preferredUsername}"',
              {
                preferredUsername: this.identity.preferredUsername,
              }
            )}`,
      confirmText: this.$t("Delete {preferredUsername}", {
        preferredUsername: this.identity.preferredUsername,
      }) as string,
      inputAttrs: {
        placeholder: this.identity.preferredUsername,
        pattern: this.identity.preferredUsername,
      },

      onConfirm: () => this.deleteIdentity(),
    });
  }

  private handleError(err: any) {
    console.error(err);

    if (err?.networkError?.name === "ServerParseError") {
      const error = err?.networkError as ServerParseError;

      if (error?.response?.status === 413) {
        const errorMessage = this.isUpdate
          ? this.$t(
              "Unable to update the profile. The avatar picture may be too heavy."
            )
          : this.$t(
              "Unable to create the profile. The avatar picture may be too heavy."
            );
        this.errors.push(errorMessage as string);
      }
    }

    if (err.graphQLErrors !== undefined) {
      err.graphQLErrors.forEach(({ message }: { message: string }) => {
        this.$notifier.error(message);
      });
    }
  }

  private async buildVariables() {
    /**
     * We set the avatar only if user has selected one
     */
    let avatarObj: Record<string, unknown> = { avatar: null };
    if (this.avatarFile) {
      avatarObj = buildFileVariable(
        this.avatarFile,
        "avatar",
        `${this.identity.preferredUsername}'s avatar`
      );
    }
    const res = { ...this.identity, ...avatarObj };
    return res;
  }

  private async redirectIfNoIdentitySelected(identityParam?: string) {
    if (identityParam) return;

    await this.loadLoggedPersonIfNeeded();

    if (this.currentActor) {
      await this.$router.push({
        params: { identityName: this.currentActor.preferredUsername },
      });
    }
  }

  private async maybeUpdateCurrentActorCache(identity: IPerson) {
    if (this.currentActor) {
      if (
        this.currentActor.preferredUsername === this.identity.preferredUsername
      ) {
        await changeIdentity(this.$apollo.provider.defaultClient, identity);
      }
      this.currentActor = identity;
    }
  }

  private async loadLoggedPersonIfNeeded(bypassCache = false) {
    if (this.currentActor) return;

    const result = await this.$apollo.query({
      query: CURRENT_ACTOR_CLIENT,
      fetchPolicy: bypassCache ? "network-only" : undefined,
    });

    this.currentActor = result.data.currentActor;
  }

  private resetFields() {
    this.identity = new Person();
    this.oldDisplayName = null;
    this.avatarFile = null;
  }
}
</script>
