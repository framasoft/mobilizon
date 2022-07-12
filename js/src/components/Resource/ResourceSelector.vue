<template>
  <div v-if="resource">
    <article class="panel is-primary">
      <h2 class="panel-heading truncate">
        {{
          $t('Move "{resourceName}"', { resourceName: initialResource.title })
        }}
      </h2>
      <a
        class="panel-block clickable flex gap-1 items-center"
        @click="resourcePath.path = resource?.parent?.path"
        v-if="resource.parent"
      >
        <span class="panel-icon">
          <ChevronUp :size="16" />
        </span>
        {{ $t("Parent folder") }}
      </a>
      <a
        class="panel-block clickable flex gap-1 items-center"
        @click="resourcePath.path = '/'"
        v-else-if="resourcePath?.path && resourcePath?.path.length > 1"
      >
        <span class="panel-icon">
          <ChevronUp :size="16" />
        </span>
        {{ $t("Parent folder") }}
      </a>
      <template v-if="resource.children">
        <a
          class="panel-block flex flex-wrap gap-1 px-2"
          v-for="element in resource.children.elements"
          :class="{
            clickable:
              element.type === 'folder' && element.id !== initialResource.id,
          }"
          :key="element.id"
          @click="goDown(element)"
        >
          <p class="truncate flex gap-1 items-center">
            <span class="panel-icon">
              <Folder :size="16" v-if="element.type === 'folder'" />
              <Link :size="16" v-else />
            </span>
            <span>{{ element.title }}</span>
          </p>
          <span v-if="element.id === initialResource.id">
            <em v-if="element.type === 'folder'"> {{ $t("(this folder)") }}</em>
            <em v-else> {{ $t("(this link)") }}</em>
          </span>
        </a>
      </template>
      <p
        class="panel-block content has-text-grey has-text-centered"
        v-if="resource.children && resource.children.total === 0"
      >
        {{ $t("No resources in this folder") }}
      </p>
      <o-pagination
        v-if="resource.children && resource.children.total > RESOURCES_PER_PAGE"
        :total="resource.children.total"
        v-model="page"
        size="small"
        :per-page="RESOURCES_PER_PAGE"
        :aria-next-label="$t('Next page')"
        :aria-previous-label="$t('Previous page')"
        :aria-page-label="$t('Page')"
        :aria-current-label="$t('Current page')"
      />
    </article>
    <div class="flex gap-2 mt-2">
      <o-button type="is-text" @click="emit('close-move-modal')">{{
        $t("Cancel")
      }}</o-button>
      <o-button
        variant="primary"
        @click="updateResource"
        :disabled="moveDisabled"
        ><template v-if="resource.path === '/'">
          {{ $t("Move resource to the root folder") }}
        </template>
        <template v-else
          >{{ $t("Move resource to {folder}", { folder: resource.title }) }}
        </template></o-button
      >
    </div>
  </div>
</template>
<script lang="ts" setup>
import { useQuery } from "@vue/apollo-composable";
import { computed, ref, watch } from "vue";
import { GET_RESOURCE } from "../../graphql/resources";
import { IResource } from "../../types/resource";
import Folder from "vue-material-design-icons/Folder.vue";
import Link from "vue-material-design-icons/Link.vue";
import ChevronUp from "vue-material-design-icons/ChevronUp.vue";

const props = defineProps<{ initialResource: IResource; username: string }>();
const emit = defineEmits(["update-resource", "close-move-modal"]);

const resourcePath = ref<{ path: string | undefined; username: string }>({
  path: props.initialResource.path,
  username: props.username,
});

const RESOURCES_PER_PAGE = 10;
const page = ref(1);

const { result: resourceResult, refetch } = useQuery<{ resource: IResource }>(
  GET_RESOURCE,
  () => {
    if (resourcePath.value?.path) {
      return {
        path: resourcePath.value?.path,
        username: props.username,
        page: page.value,
        limit: RESOURCES_PER_PAGE,
      };
    }
    return { path: "/", username: props.username };
  }
);

const resource = computed(() => resourceResult.value?.resource);

const goDown = (element: IResource): void => {
  if (element.type === "folder" && element.id !== props.initialResource.id) {
    resourcePath.value.path = element.path;
  }
};

watch(props.initialResource, () => {
  if (props.initialResource) {
    resourcePath.value.path = props.initialResource?.parent?.path;
    refetch();
  }
});

const updateResource = (): void => {
  emit(
    "update-resource",
    {
      id: props.initialResource.id,
      title: props.initialResource.title,
      parent: resourcePath.value?.path === "/" ? null : resourcePath.value,
      path: props.initialResource.path,
    },
    props.initialResource.parent
  );
};

const moveDisabled = computed((): boolean | undefined => {
  return (
    (props.initialResource.parent &&
      resourcePath.value &&
      props.initialResource.parent.path === resourcePath.value.path) ||
    (props.initialResource.parent === undefined &&
      resourcePath.value &&
      resourcePath.value.path === "/")
  );
});
</script>
<style lang="scss" scoped>
.panel {
  a.panel-block {
    cursor: default;

    &.clickable {
      cursor: pointer;
    }
  }

  &.is-primary .panel-heading {
    color: #fff;
  }
}
.buttons {
  justify-content: flex-end;
}

nav.pagination {
  margin: 0.5rem;
}
</style>
