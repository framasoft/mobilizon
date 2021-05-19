<template>
  <div class="container section" v-if="resource">
    <nav class="breadcrumb" aria-label="breadcrumbs">
      <ul>
        <li>
          <router-link
            :to="{
              name: RouteName.GROUP,
              params: { preferredUsername: usernameWithDomain(resource.actor) },
            }"
            >{{ resource.actor.name }}</router-link
          >
        </li>
        <li>
          <router-link
            :to="{
              name: RouteName.RESOURCE_FOLDER_ROOT,
              params: { preferredUsername: usernameWithDomain(resource.actor) },
            }"
            >{{ $t("Resources") }}</router-link
          >
        </li>
        <li
          :class="{
            'is-active':
              index + 1 === ResourceMixin.resourcePathArray(resource).length,
          }"
          v-for="(pathFragment, index) in filteredPath"
          :key="pathFragment"
        >
          <router-link
            :to="{
              name: RouteName.RESOURCE_FOLDER,
              params: {
                path: ResourceMixin.resourcePathArray(resource).slice(
                  0,
                  index + 1
                ),
                preferredUsername: usernameWithDomain(resource.actor),
              },
            }"
            >{{ pathFragment }}</router-link
          >
        </li>
        <li>
          <b-dropdown aria-role="list">
            <b-button class="button is-primary" slot="trigger">+</b-button>

            <b-dropdown-item aria-role="listitem" @click="createFolderModal">
              <b-icon icon="folder" />
              {{ $t("New folder") }}
            </b-dropdown-item>
            <b-dropdown-item
              aria-role="listitem"
              @click="createLinkResourceModal = true"
            >
              <b-icon icon="link" />
              {{ $t("New link") }}
            </b-dropdown-item>
            <hr
              class="dropdown-divider"
              v-if="config.resourceProviders.length"
            />
            <b-dropdown-item
              aria-role="listitem"
              v-for="resourceProvider in config.resourceProviders"
              :key="resourceProvider.software"
              @click="createResourceFromProvider(resourceProvider)"
            >
              <b-icon :icon="mapServiceTypeToIcon[resourceProvider.software]" />
              {{ createSentenceForType(resourceProvider.software) }}
            </b-dropdown-item>
          </b-dropdown>
        </li>
      </ul>
    </nav>
    <section>
      <p v-if="resource.path === '/'" class="module-description">
        {{
          $t("A place to store links to documents or resources of any type.")
        }}
      </p>
      <div class="list-header">
        <div class="list-header-right">
          <b-checkbox v-model="checkedAll" v-if="resource.children.total > 0" />
          <div class="actions" v-if="validCheckedResources.length > 0">
            <small>
              {{
                $tc("No resources selected", validCheckedResources.length, {
                  count: validCheckedResources.length,
                })
              }}
            </small>
            <b-button
              type="is-danger"
              icon-right="delete"
              size="is-small"
              @click="deleteMultipleResources"
              >{{ $t("Delete") }}</b-button
            >
          </div>
        </div>
      </div>
      <draggable
        v-model="resource.children.elements"
        :sort="false"
        :group="groupObject"
        v-if="resource.children.total > 0"
      >
        <transition-group>
          <div
            v-for="localResource in resource.children.elements"
            :key="localResource.id"
          >
            <div class="resource-item">
              <div
                class="resource-checkbox"
                :class="{ checked: checkedResources[localResource.id] }"
              >
                <b-checkbox v-model="checkedResources[localResource.id]" />
              </div>
              <resource-item
                :resource="localResource"
                v-if="localResource.type !== 'folder'"
                @delete="deleteResource"
                @rename="handleRename"
                @move="handleMove"
              />
              <folder-item
                :resource="localResource"
                :group="resource.actor"
                @delete="deleteResource"
                @rename="handleRename"
                @move="handleMove"
                v-else
              />
            </div>
          </div>
        </transition-group>
      </draggable>
      <div
        class="content has-text-centered has-text-grey"
        v-if="resource.children.total === 0"
      >
        <p>{{ $t("No resources in this folder") }}</p>
      </div>
    </section>
    <b-modal :active.sync="renameModal" has-modal-card>
      <div class="modal-card">
        <section class="modal-card-body">
          <form @submit.prevent="renameResource">
            <b-field :label="$t('Title')">
              <b-input aria-required="true" v-model="updatedResource.title" />
            </b-field>

            <b-button native-type="submit">{{
              $t("Rename resource")
            }}</b-button>
          </form>
        </section>
      </div>
    </b-modal>
    <b-modal :active.sync="moveModal" has-modal-card>
      <div class="modal-card">
        <section class="modal-card-body">
          <resource-selector
            :initialResource="updatedResource"
            :username="usernameWithDomain(resource.actor)"
            @update-resource="moveResource"
            @close-move-modal="moveModal = false"
          />
        </section>
      </div>
    </b-modal>
    <b-modal :active.sync="createResourceModal" has-modal-card>
      <div class="modal-card">
        <section class="modal-card-body">
          <form @submit.prevent="createResource">
            <b-field :label="$t('Title')">
              <b-input aria-required="true" v-model="newResource.title" />
            </b-field>

            <b-button native-type="submit">{{
              createResourceButtonLabel
            }}</b-button>
          </form>
        </section>
      </div>
    </b-modal>
    <b-modal :active.sync="createLinkResourceModal" has-modal-card>
      <div class="modal-card">
        <section class="modal-card-body">
          <b-message type="is-danger" v-if="modalError">
            {{ modalError }}
          </b-message>
          <form @submit.prevent="createResource">
            <b-field :label="$t('URL')">
              <b-input
                type="url"
                required
                v-model="newResource.resourceUrl"
                @blur="previewResource"
              />
            </b-field>

            <div class="new-resource-preview" v-if="newResource.title">
              <resource-item :resource="newResource" />
            </div>

            <b-field :label="$t('Title')">
              <b-input aria-required="true" v-model="newResource.title" />
            </b-field>

            <b-field :label="$t('Text')">
              <b-input type="textarea" v-model="newResource.summary" />
            </b-field>

            <b-button native-type="submit">{{
              $t("Create resource")
            }}</b-button>
          </form>
        </section>
      </div>
    </b-modal>
  </div>
</template>
<script lang="ts">
import { Component, Mixins, Prop, Watch } from "vue-property-decorator";
import ResourceItem from "@/components/Resource/ResourceItem.vue";
import FolderItem from "@/components/Resource/FolderItem.vue";
import Draggable from "vuedraggable";
import { RefetchQueryDescription } from "apollo-client/core/watchQueryOptions";
import { CURRENT_ACTOR_CLIENT } from "../../graphql/actor";
import { IActor, usernameWithDomain } from "../../types/actor";
import RouteName from "../../router/name";
import {
  IResource,
  mapServiceTypeToIcon,
  IProvider,
} from "../../types/resource";
import {
  CREATE_RESOURCE,
  DELETE_RESOURCE,
  PREVIEW_RESOURCE_LINK,
  GET_RESOURCE,
  UPDATE_RESOURCE,
} from "../../graphql/resources";
import { CONFIG } from "../../graphql/config";
import { IConfig } from "../../types/config.model";
import ResourceMixin from "../../mixins/resource";
import ResourceSelector from "../../components/Resource/ResourceSelector.vue";

@Component({
  components: { FolderItem, ResourceItem, Draggable, ResourceSelector },
  apollo: {
    resource: {
      query: GET_RESOURCE,
      fetchPolicy: "cache-and-network",
      variables() {
        let path = Array.isArray(this.$route.params.path)
          ? this.$route.params.path.join("/")
          : this.$route.params.path || this.path;
        path = path[0] !== "/" ? `/${path}` : path;
        return {
          path,
          username: this.$route.params.preferredUsername,
        };
      },
      error({ graphQLErrors }) {
        this.handleErrors(graphQLErrors);
      },
    },
    config: CONFIG,
    currentActor: CURRENT_ACTOR_CLIENT,
  },
})
export default class Resources extends Mixins(ResourceMixin) {
  @Prop({ required: true }) path!: string;

  resource!: IResource;

  config!: IConfig;

  currentActor!: IActor;

  RouteName = RouteName;

  ResourceMixin = ResourceMixin;

  usernameWithDomain = usernameWithDomain;

  newResource: IResource = {
    title: "",
    summary: "",
    resourceUrl: "",
    children: { elements: [], total: 0 },
    metadata: {},
    type: "link",
  };

  updatedResource: IResource = {
    title: "",
    resourceUrl: "",
    metadata: {},
    children: { elements: [], total: 0 },
    path: undefined,
  };

  checkedResources: { [key: string]: boolean } = {};

  validCheckedResources: string[] = [];

  checkedAll = false;

  createResourceModal = false;

  createLinkResourceModal = false;

  moveModal = false;

  renameModal = false;

  modalError = "";

  groupObject: Record<string, unknown> = {
    name: "resources",
    pull: "clone",
    put: true,
  };

  mapServiceTypeToIcon = mapServiceTypeToIcon;

  get actualPath(): string {
    const path = Array.isArray(this.$route.params.path)
      ? this.$route.params.path.join("/")
      : this.$route.params.path || this.path;
    return path[0] !== "/" ? `/${path}` : path;
  }

  get filteredPath(): string[] {
    if (this.resource && this.resource.path !== "/") {
      return ResourceMixin.resourcePathArray(this.resource);
    }
    return [];
  }

  async createResource(): Promise<void> {
    if (!this.resource.actor) return;
    this.modalError = "";
    try {
      await this.$apollo.mutate({
        mutation: CREATE_RESOURCE,
        variables: {
          title: this.newResource.title,
          summary: this.newResource.summary,
          actorId: this.resource.actor.id,
          resourceUrl: this.newResource.resourceUrl,
          parentId:
            this.resource.id && this.resource.id.startsWith("root_")
              ? null
              : this.resource.id,
          type: this.newResource.type,
        },
        refetchQueries: () => this.postRefreshQueries(),
      });
      this.createLinkResourceModal = false;
      this.createResourceModal = false;
      this.newResource.title = "";
      this.newResource.summary = "";
      this.newResource.resourceUrl = "";
    } catch (err) {
      console.error(err);
      this.modalError = err.graphQLErrors[0].message;
    }
  }

  async previewResource(): Promise<void> {
    this.modalError = "";
    try {
      if (this.newResource.resourceUrl === "") return;
      const { data } = await this.$apollo.mutate({
        mutation: PREVIEW_RESOURCE_LINK,
        variables: {
          resourceUrl: this.newResource.resourceUrl,
        },
      });
      this.newResource.title = data.previewResourceLink.title;
      this.newResource.summary = data.previewResourceLink.description;
      this.newResource.metadata = data.previewResourceLink;
      this.newResource.type = "link";
    } catch (err) {
      console.error(err);
      this.modalError = err.graphQLErrors[0].message;
    }
  }

  createSentenceForType(type: string): string {
    switch (type) {
      case "folder":
        return this.$t("Create a folder") as string;
      case "pad":
        return this.$t("Create a pad") as string;
      case "calc":
        return this.$t("Create a calc") as string;
      case "visio":
        return this.$t("Create a videoconference") as string;
      default:
        return "";
    }
  }

  createFolderModal(): void {
    this.newResource.type = "folder";
    this.createResourceModal = true;
  }

  createResourceFromProvider(provider: IProvider): void {
    this.newResource.resourceUrl = Resources.generateFullResourceUrl(provider);
    this.newResource.type = provider.software;
    this.createResourceModal = true;
  }

  static generateFullResourceUrl(provider: IProvider): string {
    const randomString = [...Array(10)]
      .map(() => Math.random().toString(36)[3])
      .join("")
      .replace(/(.|$)/g, (c) =>
        c[!Math.round(Math.random()) ? "toString" : "toLowerCase"]()
      );
    switch (provider.type) {
      case "ethercalc":
      case "etherpad":
      case "jitsi":
      default:
        return `${provider.endpoint}${randomString}`;
    }
  }

  get createResourceButtonLabel(): string {
    if (!this.newResource.type) return "";
    return this.createSentenceForType(this.newResource.type);
  }

  @Watch("checkedAll")
  watchCheckedAll(): void {
    this.resource.children.elements.forEach(({ id }) => {
      if (!id) return;
      this.checkedResources[id] = this.checkedAll;
    });
  }

  @Watch("checkedResources", { deep: true })
  watchValidCheckedResources(): string[] {
    const validCheckedResources: string[] = [];
    Object.entries(this.checkedResources).forEach(([key, value]) => {
      if (value) {
        validCheckedResources.push(key);
      }
    });
    this.validCheckedResources = validCheckedResources;
    return this.validCheckedResources;
  }

  async deleteMultipleResources(): Promise<void> {
    this.validCheckedResources.forEach(async (resourceID) => {
      await this.deleteResource(resourceID);
    });
  }

  // eslint-disable-next-line class-methods-use-this
  private postRefreshQueries(): RefetchQueryDescription {
    return [
      {
        query: GET_RESOURCE,
        variables: {
          path: this.actualPath,
          username: this.$route.params.preferredUsername,
        },
      },
    ];
  }

  async deleteResource(resourceID: string): Promise<void> {
    try {
      await this.$apollo.mutate({
        mutation: DELETE_RESOURCE,
        variables: {
          id: resourceID,
        },
        refetchQueries: () => this.postRefreshQueries(),
      });
      this.validCheckedResources = this.validCheckedResources.filter(
        (id) => id !== resourceID
      );
      delete this.checkedResources[resourceID];
    } catch (e) {
      console.error(e);
    }
  }

  handleRename(resource: IResource): void {
    console.log("handleRename");
    this.renameModal = true;
    this.updatedResource = { ...resource };
  }

  handleMove(resource: IResource): void {
    this.moveModal = true;
    this.updatedResource = { ...resource };
  }

  async moveResource(
    resource: IResource,
    oldParent: IResource | undefined
  ): Promise<void> {
    const parentPath =
      oldParent && oldParent.path ? oldParent.path || "/" : "/";
    await this.updateResource(resource, parentPath);
    this.moveModal = false;
  }

  async renameResource(): Promise<void> {
    await this.updateResource(this.updatedResource);
    this.renameModal = false;
  }

  async updateResource(
    resource: IResource,
    parentPath: string | null = null
  ): Promise<void> {
    try {
      await this.$apollo.mutate<{ updateResource: IResource }>({
        mutation: UPDATE_RESOURCE,
        variables: {
          id: resource.id,
          title: resource.title,
          parentId: resource.parent ? resource.parent.id : null,
          path: resource.path,
        },
        refetchQueries: () => this.postRefreshQueries(),
        update: (store, { data }) => {
          if (!data || data.updateResource == null || parentPath == null)
            return;
          if (!this.resource.actor) return;

          console.log("Removing ressource from old parent");
          const oldParentCachedData = store.readQuery<{ resource: IResource }>({
            query: GET_RESOURCE,
            variables: {
              path: parentPath,
              username: this.resource.actor.preferredUsername,
            },
          });
          if (oldParentCachedData == null) return;
          const { resource: oldParentCachedResource } = oldParentCachedData;
          if (oldParentCachedResource == null) {
            console.error(
              "Cannot update resource cache, because of null value."
            );
            return;
          }
          const updatedResource: IResource = data.updateResource;

          // eslint-disable-next-line vue/max-len
          oldParentCachedResource.children.elements =
            oldParentCachedResource.children.elements.filter(
              (cachedResource) => cachedResource.id !== updatedResource.id
            );

          store.writeQuery({
            query: GET_RESOURCE,
            variables: {
              path: parentPath,
              username: this.resource.actor.preferredUsername,
            },
            data: { oldParentCachedResource },
          });
          console.log("Finished removing ressource from old parent");

          console.log("Adding resource to new parent");
          if (!updatedResource.parent || !updatedResource.parent.path) {
            console.log("No cache found for new parent");
            return;
          }
          const newParentCachedData = store.readQuery<{ resource: IResource }>({
            query: GET_RESOURCE,
            variables: {
              path: updatedResource.parent.path,
              username: this.resource.actor.preferredUsername,
            },
          });
          if (newParentCachedData == null) return;
          const { resource: newParentCachedResource } = newParentCachedData;
          if (newParentCachedResource == null) {
            console.error(
              "Cannot update resource cache, because of null value."
            );
            return;
          }

          newParentCachedResource.children.elements.push(resource);

          store.writeQuery({
            query: GET_RESOURCE,
            variables: {
              path: updatedResource.parent.path,
              username: this.resource.actor.preferredUsername,
            },
            data: { newParentCachedResource },
          });
          console.log("Finished adding resource to new parent");
        },
      });
    } catch (e) {
      console.error(e);
    }
  }

  handleErrors(errors: any[]): void {
    if (errors.some((error) => error.status_code === 404)) {
      this.$router.replace({ name: RouteName.PAGE_NOT_FOUND });
    }
  }
}
</script>
<style lang="scss" scoped>
.container.section {
  background: $white;
}

nav.breadcrumb ul {
  align-items: center;

  li:last-child .dropdown {
    margin-left: 5px;

    a {
      justify-content: left;
      color: inherit;
      padding: 0.375rem 1rem;
    }
  }
}

.list-header {
  display: flex;
  justify-content: space-between;

  .list-header-right {
    display: flex;
    align-items: center;

    .actions {
      margin-right: 5px;

      & > * {
        margin-left: 5px;
      }
    }
  }
}

.resource-item,
.new-resource-preview {
  display: flex;
  font-size: 14px;
  border: 1px solid #c0cdd9;
  border-radius: 4px;
  color: #444b5d;
  margin-top: 14px;

  .resource-checkbox {
    align-self: center;
    padding: 0 3px 0 10px;
    opacity: 0.3;
  }

  &:hover .resource-checkbox,
  .resource-checkbox.checked {
    opacity: 1;
  }
}
</style>
