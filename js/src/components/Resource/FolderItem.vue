<template>
  <div class="resource-wrapper bg-white dark:bg-transparent" dir="auto">
    <router-link
      :to="{
        name: RouteName.RESOURCE_FOLDER,
        params: {
          path: resourcePathArray(resource),
          preferredUsername: usernameWithDomain(group),
        },
      }"
    >
      <div class="preview text-mbz-purple dark:text-mbz-purple-300">
        <Folder :size="48" />
      </div>
      <div class="body">
        <h3>{{ resource.title }}</h3>
        <span class="host" v-if="inline && resource.updatedAt">{{
          formatDateTimeString(resource.updatedAt?.toString())
        }}</span>
      </div>
      <draggable
        v-if="!inline"
        class="dropzone"
        v-model="list"
        itemKey="id"
        :sort="false"
        :group="groupObject"
        @change="onChange"
      >
        <template #item="{ element }">
          <div>{{ element.name }}</div>
        </template>
      </draggable>
    </router-link>
    <resource-dropdown
      class="actions"
      v-if="!inline"
      @delete="emit('delete', resource.id as string)"
      @move="emit('move', resource)"
      @rename="emit('rename', resource)"
    />
  </div>
</template>
<script lang="ts" setup>
import { useRouter } from "vue-router";
import Draggable from "zhyswan-vuedraggable";
import { IResource } from "@/types/resource";
import RouteName from "@/router/name";
import { IMinimalActor, usernameWithDomain } from "@/types/actor";
import ResourceDropdown from "./ResourceDropdown.vue";
import { UPDATE_RESOURCE } from "@/graphql/resources";
import { inject, ref } from "vue";
import { formatDateTimeString } from "@/filters/datetime";
import { useMutation } from "@vue/apollo-composable";
import { resourcePathArray } from "@/components/Resource/utils";
import Folder from "vue-material-design-icons/Folder.vue";
import { Snackbar } from "@/plugins/snackbar";

const props = withDefaults(
  defineProps<{
    resource: IResource;
    group: IMinimalActor;
    inline?: boolean;
  }>(),
  { inline: false }
);

const emit = defineEmits<{
  (e: "move", resource: IResource): void;
  (e: "rename", resource: IResource): void;
  (e: "delete", resourceID: string): void;
}>();

const list = ref([]);

const groupObject: Record<string, unknown> = {
  name: `folder-${props.resource?.title}`,
  pull: false,
  put: ["resources"],
};

const onChange = async (evt: any) => {
  if (evt.added && evt.added.element) {
    const movedResource = evt.added.element as IResource;
    console.debug(
      `Moving resource « ${movedResource.title} » to path « ${props.resource.path} » (new parent ${props.resource.id})`
    );
    moveResource({
      id: movedResource.id,
      path: props.resource.path,
      parentId: props.resource.id,
    });
  }
  return undefined;
};

const {
  mutate: moveResource,
  onDone: onMovedResource,
  onError: onMovedResourceError,
} = useMutation<{ updateResource: IResource }>(UPDATE_RESOURCE);

const router = useRouter();

onMovedResource(({ data }) => {
  if (data?.updateResource && props.resource.path) {
    return router.push({
      name: RouteName.RESOURCE_FOLDER,
      params: {
        path: resourcePathArray(props.resource),
        preferredUsername: props.group.preferredUsername,
      },
    });
  }
});
const snackbar = inject<Snackbar>("snackbar");

onMovedResourceError((e) => {
  snackbar?.open({
    message: e.message,
    variant: "danger",
    position: "bottom",
  });
  return undefined;
});
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
  // color: #444b5d;
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
    padding: 8px;
    flex: 1 1 auto;
    overflow: hidden;

    h3 {
      white-space: nowrap;
      display: block;
      font-weight: 500;
      margin-bottom: 5px;
      overflow: hidden;
      text-overflow: ellipsis;
      text-decoration: none;
    }
  }
}
</style>
