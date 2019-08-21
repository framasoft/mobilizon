<template>
  <div class="root">
    <h1 class="title">
      <span v-if="isUpdate">{{ identity.displayName() }}</span>
      <translate v-else>I create an identity</translate>
    </h1>

    <picture-upload v-model="avatarFile" class="picture-upload"></picture-upload>

    <b-field :label="$gettext('Display name')">
      <b-input aria-required="true" required v-model="identity.name" @input="autoUpdateUsername($event)"/>
    </b-field>

    <b-field :label="$gettext('Username')">
      <b-field>
        <b-input aria-required="true" required v-model="identity.preferredUsername" :disabled="isUpdate"/>

        <p class="control">
          <span class="button is-static">@{{ getInstanceHost() }}</span>
        </p>
      </b-field>
    </b-field>

    <b-field :label="$gettext('Description')">
      <b-input type="textarea" aria-required="false" v-model="identity.summary"/>
    </b-field>

    <b-field class="submit">
      <div class="control">
        <button v-translate type="button" class="button is-primary" @click="submit()">
          Save
        </button>
      </div>
    </b-field>

    <div class="delete-identity" v-if="isUpdate">
      <span v-translate @click="openDeleteIdentityConfirmation()">
        Delete this identity
      </span>
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
</style>

<script lang="ts">
import { Component, Prop, Vue, Watch } from 'vue-property-decorator';
import { CREATE_PERSON, DELETE_PERSON, FETCH_PERSON, IDENTITIES, LOGGED_PERSON, UPDATE_PERSON } from '../../../graphql/actor';
import { IPerson, Person } from '@/types/actor';
import PictureUpload from '@/components/PictureUpload.vue';
import { MOBILIZON_INSTANCE_HOST } from '@/api/_entrypoint';
import { Dialog } from 'buefy/dist/components/dialog';
import { RouteName } from '@/router';

@Component({
  components: {
    PictureUpload,
    Dialog,
  },
})
export default class EditIdentity extends Vue {
  @Prop({ type: Boolean }) isUpdate!: boolean;

  errors: string[] = [];

  identityName!: string | undefined;
  avatarFile: File | null = null;
  identity = new Person();

  private oldDisplayName: string | null = null;
  private loggedPerson: IPerson | null = null;

  @Watch('isUpdate')
  async isUpdateChanged () {
    this.resetFields();
  }

  @Watch('$route.params.identityName', { immediate: true })
  async onIdentityParamChanged (val: string) {
    // Only used when we update the identity
    if (this.isUpdate !== true) return;

    await this.redirectIfNoIdentitySelected(val);

    this.resetFields();
    this.identityName = val;

    if (this.identityName) {
      this.identity = await this.getIdentity();

      this.avatarFile = await this.getAvatarFileFromIdentity(this.identity);
    }
  }

  submit() {
    if (this.isUpdate) return this.updateIdentity();

    return this.createIdentity();
  }

  autoUpdateUsername(newDisplayName: string | null) {
    const oldUsername = this.convertToUsername(this.oldDisplayName);

    if (this.identity.preferredUsername === oldUsername) {
      this.identity.preferredUsername = this.convertToUsername(newDisplayName);
    }

    this.oldDisplayName = newDisplayName;
  }

  async deleteIdentity() {
    try {
      await this.$apollo.mutate({
        mutation: DELETE_PERSON,
        variables: this.identity,
        update: (store) => {
          const data = store.readQuery<{ identities: IPerson[] }>({ query: IDENTITIES });

          if (data) {
            data.identities = data.identities.filter(i => i.id !== this.identity.id);

            store.writeQuery({ query: IDENTITIES, data });
          }
        },
      });


      this.$notifier.success(
        this.$gettextInterpolate('Identity %{displayName} deleted', { displayName: this.identity.displayName() }),
      );

      await this.loadLoggedPersonIfNeeded();

      // Refresh the loaded person if we deleted the default identity
      if (this.loggedPerson && this.identity.id === this.loggedPerson.id) {
        this.loggedPerson = null;
        await this.loadLoggedPersonIfNeeded(true);
      }

      await this.redirectIfNoIdentitySelected();
    } catch (err) {
      this.handleError(err);
    }
  }

  async updateIdentity() {
    try {
      await this.$apollo.mutate({
        mutation: UPDATE_PERSON,
        variables: this.buildVariables(),
        update: (store, { data: { updatePerson } }) => {
          const data = store.readQuery<{ identities: IPerson[] }>({ query: IDENTITIES });

          if (data) {
            const index = data.identities.findIndex(i => i.id === this.identity.id);

            this.$set(data.identities, index, updatePerson);

            store.writeQuery({ query: IDENTITIES, data });
          }
        },
      });

      this.$notifier.success(
        this.$gettextInterpolate('Identity %{displayName} updated', { displayName: this.identity.displayName() }),
      );
    } catch (err) {
      this.handleError(err);
    }
  }

  async createIdentity() {
    try {
      await this.$apollo.mutate({
        mutation: CREATE_PERSON,
        variables: this.buildVariables(),
        update: (store, { data: { createPerson } }) => {
          const data = store.readQuery<{ identities: IPerson[] }>({ query: IDENTITIES });

          if (data) {
            data.identities.push(createPerson);

            store.writeQuery({ query: IDENTITIES, data });
          }
        },
      });

      this.$router.push({ name: RouteName.UPDATE_IDENTITY, params: { identityName: this.identity.preferredUsername } });

      this.$notifier.success(
        this.$gettextInterpolate('Identity %{displayName} created', { displayName: this.identity.displayName() }),
      );
    } catch (err) {
      this.handleError(err);
    }
  }

  getInstanceHost() {
    return MOBILIZON_INSTANCE_HOST;
  }

  openDeleteIdentityConfirmation() {
    this.$buefy.dialog.prompt({
      type: 'is-danger',
      title: this.$gettext('Delete your identity'),
      message: this.$gettextInterpolate(
        'To confirm, type your identity username "%{preferredUsername}"',
        { preferredUsername: this.identity.preferredUsername },
      ),
      confirmText: this.$gettextInterpolate(
        'Delete %{preferredUsername}',
        { preferredUsername: this.identity.preferredUsername },
      ),
      inputAttrs: {
        placeholder: this.identity.preferredUsername,
        pattern: this.identity.preferredUsername,
      },

      onConfirm: () => this.deleteIdentity(),
    });
  }

  private async getIdentity() {
    const result = await this.$apollo.query({
      query: FETCH_PERSON,
      variables: {
        name: this.identityName,
      },
    });

    return new Person(result.data.person);
  }

  private async getAvatarFileFromIdentity(identity: IPerson) {
    if (!identity.avatar) return null;

    const response = await fetch(identity.avatar.url);
    const blob = await response.blob();

    return new File([blob], identity.avatar.name);
  }

  private handleError(err: any) {
    console.error(err);

    err.graphQLErrors.forEach(({ message }) => {
      this.errors.push(message);
    });
  }

  private convertToUsername(value: string | null) {
    if (!value) return '';

    return value.toLowerCase()
                .replace(/ /g, '_')
                .replace(/[^a-z0-9._]/g, '');
  }

  private buildVariables() {
    let avatarObj = {};
    if (this.avatarFile) {
      avatarObj = {
        avatar: {
          picture: {
            name: this.avatarFile.name,
            alt: `${this.identity.preferredUsername}'s avatar`,
            file: this.avatarFile,
          },
        },
      };
    }

    return Object.assign({}, this.identity, avatarObj);
  }

  private async redirectIfNoIdentitySelected (identityParam?: string) {
    if (!!identityParam) return;

    await this.loadLoggedPersonIfNeeded();

    if (!!this.loggedPerson) {
      this.$router.push({ params: { identityName: this.loggedPerson.preferredUsername } });
    }
  }

  private async loadLoggedPersonIfNeeded (bypassCache = false) {
    if (this.loggedPerson) return;

    const result = await this.$apollo.query({
      query: LOGGED_PERSON,
      fetchPolicy: bypassCache ? 'network-only' : undefined,
    });

    this.loggedPerson = result.data.loggedPerson;
  }

  private resetFields () {
    this.identityName = undefined;
    this.identity = new Person();
    this.oldDisplayName = null;
    this.avatarFile = null;
  }
}
</script>
