<template>
  <div class="root">
    <h1 v-translate>Create a new group</h1>

    <div>
      <b-field :label="$gettext('Group name')">
        <b-input aria-required="true" required v-model="group.preferred_username"/>
      </b-field>

      <b-field :label="$gettext('Group full name')">
        <b-input aria-required="true" required v-model="group.name"/>
      </b-field>

      <b-field :label="$gettext('Description')">
        <b-input aria-required="true" required v-model="group.description" type="textarea"/>
      </b-field>

      <div>
        Avatar
        <picture-upload v-model="avatarFile"></picture-upload>
      </div>

      <div>
        Banner
        <picture-upload v-model="avatarFile"></picture-upload>
      </div>

      <button class="button is-primary" @click="createGroup()">
        <translate>Create my group</translate>
      </button>
    </div>
  </div>
</template>

<style lang="scss" scoped>
  .root {
    width: 400px;
    margin: auto;
  }
</style>

<script lang="ts">
import { Component, Vue } from 'vue-property-decorator';
import { Group, IPerson } from '@/types/actor';
import { CREATE_GROUP, LOGGED_PERSON } from '@/graphql/actor';
import { RouteName } from '@/router';
import PictureUpload from '@/components/PictureUpload.vue';

@Component({
  components: {
    PictureUpload,
  },
  apollo: {
    loggedPerson: {
      query: LOGGED_PERSON,
    },
  },
})
export default class CreateGroup extends Vue {
  loggedPerson!: IPerson;

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

      this.$router.push({ name: RouteName.GROUP, params: { identityName: this.group.preferredUsername } });

      this.$notifier.success(
        this.$gettextInterpolate('Group %{displayName} created', { displayName: this.group.displayName() }),
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
      creatorActorId: this.loggedPerson.id,
    };

    return Object.assign({}, this.group, avatarObj, bannerObj, currentActor);
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
