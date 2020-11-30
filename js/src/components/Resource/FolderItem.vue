<template>
  <div class="resource-wrapper">
    <router-link
      :to="{
        name: RouteName.RESOURCE_FOLDER,
        params: {
          path: ResourceMixin.resourcePathArray(resource),
          preferredUsername: usernameWithDomain(group),
        },
      }"
    >
      <div class="preview">
        <b-icon icon="folder" size="is-large" />
      </div>
      <div class="body">
        <h3>{{ resource.title }}</h3>
        <span class="host" v-if="inline">{{
          resource.updatedAt | formatDateTimeString
        }}</span>
      </div>
      <draggable
        v-if="!inline"
        class="dropzone"
        v-model="list"
        :sort="false"
        :group="groupObject"
        @change="onChange"
      />
    </router-link>
    <resource-dropdown
      class="actions"
      v-if="!inline"
      @delete="$emit('delete', resource.id)"
      @move="$emit('move', resource)"
      @rename="$emit('rename', resource)"
    />
  </div>
</template>
<script lang="ts">
import { Component, Mixins, Prop } from "vue-property-decorator";
import { Route } from "vue-router";
import Draggable, { ChangeEvent } from "vuedraggable";
import { SnackbarProgrammatic as Snackbar } from "buefy";
import { IResource } from "../../types/resource";
import RouteName from "../../router/name";
import ResourceMixin from "../../mixins/resource";
import { IGroup, usernameWithDomain } from "../../types/actor";
import ResourceDropdown from "./ResourceDropdown.vue";
import { UPDATE_RESOURCE } from "../../graphql/resources";

@Component({
  components: { Draggable, ResourceDropdown },
})
export default class FolderItem extends Mixins(ResourceMixin) {
  @Prop({ required: true, type: Object }) resource!: IResource;

  @Prop({ required: true, type: Object }) group!: IGroup;

  @Prop({ required: false, default: false }) inline!: boolean;

  list = [];

  groupObject: Record<string, unknown> = {
    name: `folder-${this.resource.title}`,
    pull: false,
    put: ["resources"],
  };

  RouteName = RouteName;

  ResourceMixin = ResourceMixin;

  usernameWithDomain = usernameWithDomain;

  async onChange(evt: ChangeEvent<IResource>): Promise<Route | undefined> {
    if (evt.added && evt.added.element) {
      const movedResource = evt.added.element as IResource;
      const updatedResource = await this.moveResource(movedResource);
      if (updatedResource && this.resource.path) {
        // eslint-disable-next-line
        // @ts-ignore
        return this.$router.push({
          name: RouteName.RESOURCE_FOLDER,
          params: {
            // eslint-disable-next-line
            // @ts-ignore
            path: ResourceMixin.resourcePathArray(this.resource),
            preferredUsername: this.group.preferredUsername,
          },
        });
      }
    }
    return undefined;
  }

  async moveResource(resource: IResource): Promise<IResource | undefined> {
    try {
      const { data } = await this.$apollo.mutate<{ updateResource: IResource }>(
        {
          mutation: UPDATE_RESOURCE,
          variables: {
            id: resource.id,
            path: `${this.resource.path}/${resource.title}`,
            parentId: this.resource.id,
          },
        }
      );
      if (!data) {
        console.error("Error while updating resource");
        return undefined;
      }
      return data.updateResource;
    } catch (e) {
      Snackbar.open({
        message: e.message,
        type: "is-danger",
        position: "is-bottom",
      });
      return undefined;
    }
  }
}
</script>
<style lang="scss" scoped>
.resource-wrapper {
  display: flex;
  flex: 1;
  align-items: center;

  .actions {
    flex: 0;
    display: block;
    margin: auto 1rem auto 2rem;
    cursor: pointer;
  }
}

.dropzone {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  z-index: 10;
}

a {
  display: flex;
  font-size: 14px;
  color: #444b5d;
  text-decoration: none;
  overflow: hidden;
  flex: 1;
  position: relative;

  .preview {
    flex: 0 0 50px;
    position: relative;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .body {
    padding: 10px 8px 8px;
    flex: 1 1 auto;
    overflow: hidden;

    h3 {
      white-space: nowrap;
      display: block;
      font-weight: 500;
      margin-bottom: 5px;
      color: $primary;
      overflow: hidden;
      text-overflow: ellipsis;
      text-decoration: none;
    }
  }
}
</style>
