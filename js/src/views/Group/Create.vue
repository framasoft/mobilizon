<template>
  <section class="section container">
    <h1 class="title">{{ $t("Create a new group") }}</h1>

    <b-message type="is-danger" v-for="(value, index) in errors" :key="index">
      {{ value }}
    </b-message>

    <form @submit.prevent="createGroup">
      <b-field :label="$t('Group display name')">
        <b-input aria-required="true" required v-model="group.name" />
      </b-field>

      <div class="field">
        <label class="label">{{ $t("Federated Group Name") }}</label>
        <div class="field-body">
          <b-field
            :message="
              $t(
                'Only alphanumeric lowercased characters and underscores are supported.'
              )
            "
          >
            <b-input
              ref="preferredUsernameInput"
              aria-required="true"
              required
              expanded
              v-model="group.preferredUsername"
              pattern="[a-z0-9_]+"
              :useHtml5Validation="true"
              :validation-message="
                group.preferredUsername
                  ? $t(
                      'Only alphanumeric lowercased characters and underscores are supported.'
                    )
                  : null
              "
            />
            <p class="control">
              <span class="button is-static">@{{ host }}</span>
            </p>
          </b-field>
        </div>
        <p
          v-html="
            $t(
              'This is like your federated username (<code>{username}</code>) for groups. It will allow the group to be found on the federation, and is guaranteed to be unique.',
              { username: usernameWithDomain(currentActor, true) }
            )
          "
        />
      </div>

      <b-field :label="$t('Description')">
        <b-input v-model="group.summary" type="textarea" />
      </b-field>

      <div>
        <b>{{ $t("Avatar") }}</b>
        <picture-upload
          :textFallback="$t('Avatar')"
          v-model="avatarFile"
          :maxSize="avatarMaxSize"
        />
      </div>

      <div>
        <b>{{ $t("Banner") }}</b>
        <picture-upload
          :textFallback="$t('Banner')"
          v-model="bannerFile"
          :maxSize="bannerMaxSize"
        />
      </div>

      <button class="button is-primary" native-type="submit">
        {{ $t("Create my group") }}
      </button>
    </form>
  </section>
</template>

<script lang="ts">
import { Component, Watch } from "vue-property-decorator";
import { Group, IPerson, usernameWithDomain } from "@/types/actor";
import { CURRENT_ACTOR_CLIENT, PERSON_MEMBERSHIPS } from "@/graphql/actor";
import { CREATE_GROUP } from "@/graphql/group";
import { mixins } from "vue-class-component";
import IdentityEditionMixin from "@/mixins/identityEdition";
import { MemberRole } from "@/types/enums";
import RouteName from "../../router/name";
import { convertToUsername } from "../../utils/username";
import PictureUpload from "../../components/PictureUpload.vue";
import { ErrorResponse } from "apollo-link-error";
import { ServerParseError } from "apollo-link-http-common";
import { CONFIG } from "@/graphql/config";
import { IConfig } from "@/types/config.model";

@Component({
  components: {
    PictureUpload,
  },
  apollo: {
    currentActor: {
      query: CURRENT_ACTOR_CLIENT,
    },
    config: CONFIG,
  },
})
export default class CreateGroup extends mixins(IdentityEditionMixin) {
  currentActor!: IPerson;

  group = new Group();

  config!: IConfig;

  avatarFile: File | null = null;

  bannerFile: File | null = null;

  errors: string[] = [];

  usernameWithDomain = usernameWithDomain;

  async createGroup(): Promise<void> {
    try {
      this.errors = [];
      await this.$apollo.mutate({
        mutation: CREATE_GROUP,
        variables: this.buildVariables(),
        update: (store, { data: { createGroup } }) => {
          const query = {
            query: PERSON_MEMBERSHIPS,
            variables: {
              id: this.currentActor.id,
            },
          };
          const membershipData = store.readQuery<{ person: IPerson }>(query);
          if (!membershipData) return;
          const { person } = membershipData;
          person.memberships.elements.push({
            parent: createGroup,
            role: MemberRole.ADMINISTRATOR,
            actor: this.currentActor,
            insertedAt: new Date().toString(),
            updatedAt: new Date().toString(),
          });
          store.writeQuery({ ...query, data: { person } });
        },
      });

      await this.$router.push({
        name: RouteName.GROUP,
        params: { preferredUsername: usernameWithDomain(this.group) },
      });

      this.$notifier.success(
        this.$t("Group {displayName} created", {
          displayName: this.group.displayName(),
        }) as string
      );
    } catch (err) {
      this.handleError(err);
    }
  }

  // eslint-disable-next-line class-methods-use-this
  get host(): string {
    return window.location.hostname;
  }

  get avatarMaxSize(): number | undefined {
    return this?.config?.uploadLimits?.avatar;
  }

  get bannerMaxSize(): number | undefined {
    return this?.config?.uploadLimits?.banner;
  }

  @Watch("group.name")
  updateUsername(groupName: string): void {
    this.group.preferredUsername = convertToUsername(groupName);
  }

  private buildVariables() {
    let avatarObj = {};
    let bannerObj = {};

    if (this.avatarFile) {
      avatarObj = {
        avatar: {
          media: {
            name: this.avatarFile.name,
            alt: `${this.group.preferredUsername}'s avatar`,
            file: this.avatarFile,
          },
        },
      };
    }

    if (this.bannerFile) {
      bannerObj = {
        banner: {
          media: {
            name: this.bannerFile.name,
            alt: `${this.group.preferredUsername}'s banner`,
            file: this.bannerFile,
          },
        },
      };
    }

    return {
      ...this.group,
      ...avatarObj,
      ...bannerObj,
    };
  }

  private handleError(err: ErrorResponse) {
    if (err?.networkError?.name === "ServerParseError") {
      const error = err?.networkError as ServerParseError;

      if (error?.response?.status === 413) {
        this.errors.push(
          this.$t(
            "Unable to create the group. One of the pictures may be too heavy."
          ) as string
        );
      }
    }
    this.errors.push(
      ...(err.graphQLErrors || []).map(
        ({ message }: { message: string }) => message
      )
    );
  }
}
</script>

<style>
.markdown-render h1 {
  font-size: 2em;
}
</style>
