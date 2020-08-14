<template>
  <section class="section container">
    <h1>{{ $t("Create a new group") }}</h1>

    <div>
      <b-field :label="$t('Group name')">
        <b-input aria-required="true" required v-model="group.preferredUsername" />
      </b-field>

      <b-field :label="$t('Group full name')">
        <b-input aria-required="true" required v-model="group.name" />
      </b-field>

      <b-field :label="$t('Description')">
        <b-input aria-required="true" required v-model="group.summary" type="textarea" />
      </b-field>

      <div>
        Avatar
        <picture-upload v-model="avatarFile" />
      </div>

      <div>
        Banner
        <picture-upload v-model="avatarFile" />
      </div>

      <button class="button is-primary" @click="createGroup()">{{ $t("Create my group") }}</button>
    </div>
  </section>
</template>

<script lang="ts">
import { Component, Vue } from "vue-property-decorator";
import { Group, IPerson } from "@/types/actor";
import { CURRENT_ACTOR_CLIENT } from "@/graphql/actor";
import { CREATE_GROUP } from "@/graphql/group";
import PictureUpload from "@/components/PictureUpload.vue";
import RouteName from "../../router/name";

@Component({
  components: {
    PictureUpload,
  },
  apollo: {
    currentActor: {
      query: CURRENT_ACTOR_CLIENT,
    },
  },
})
export default class CreateGroup extends Vue {
  currentActor!: IPerson;

  group = new Group();

  avatarFile: File | null = null;

  bannerFile: File | null = null;

  async createGroup() {
    try {
      await this.$apollo.mutate({
        mutation: CREATE_GROUP,
        variables: this.buildVariables(),
        update: (store, { data: { createGroup } }) => {
          // TODO: update group list cache
        },
      });

      await this.$router.push({
        name: RouteName.GROUP,
        params: { identityName: this.group.preferredUsername },
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

  private buildVariables() {
    let avatarObj = {};
    let bannerObj = {};

    if (this.avatarFile) {
      avatarObj = {
        avatar: {
          picture: {
            name: this.avatarFile.name,
            alt: `${this.group.preferredUsername}'s avatar`,
            file: this.avatarFile,
          },
        },
      };
    }

    if (this.bannerFile) {
      bannerObj = {
        picture: {
          name: this.bannerFile.name,
          alt: `${this.group.preferredUsername}'s banner`,
          file: this.bannerFile,
        },
      };
    }

    const currentActor = {
      creatorActorId: this.currentActor.id,
    };

    return {
      ...this.group,
      ...avatarObj,
      ...bannerObj,
      ...currentActor,
    };
  }

  private handleError(err: any) {
    console.error(err);
  }
}
</script>

<style>
.markdown-render h1 {
  font-size: 2em;
}
</style>
