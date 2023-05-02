<template>
  <div v-if="resource">
    <article class="">
      <h2 class="mb-2">
        {{
          t('Move "{resourceName}"', { resourceName: initialResource.title })
        }}
      </h2>
      <a
        class="cursor-pointer flex gap-1 items-center border p-2"
        @click="goUp()"
        v-if="resource.parent"
      >
        <ChevronUp :size="16" />
        {{ t("Parent folder") }}
      </a>
      <a
        class="cursor-pointer flex gap-1 items-center border p-2"
        @click="resourcePath.path = '/'"
        v-else-if="resourcePath?.path && resourcePath?.path.length > 1"
      >
        <ChevronUp :size="16" />
        {{ t("Parent folder") }}
      </a>
      <template v-if="resource.children">
        <a
          class="cursor-pointer flex flex-wrap gap-1 p-2 border"
          v-for="element in resource.children.elements"
          :class="{
            clickable:
              element.type === 'folder' && element.id !== initialResource.id,
          }"
          :key="element.id"
          @click="goDown(element)"
        >
          <p class="truncate flex gap-1 items-center">
            <Folder :size="16" v-if="element.type === 'folder'" />
            <Link :size="16" v-else />
            <span>{{ element.title }}</span>
          </p>
          <span v-if="element.id === initialResource.id">
            <em v-if="element.type === 'folder'"> {{ t("(this folder)") }}</em>
            <em v-else> {{ t("(this link)") }}</em>
          </span>
        </a>
      </template>
      <p class="" v-if="resource.children && resource.children.total === 0">
        {{ t("No resources in this folder") }}
      </p>
      <o-pagination
        v-if="resource.children && resource.children.total > RESOURCES_PER_PAGE"
        :total="resource.children.total"
        v-model:current="page"
        size="small"
        :per-page="RESOURCES_PER_PAGE"
        :aria-next-label="t('Next page')"
        :aria-previous-label="t('Previous page')"
        :aria-page-label="t('Page')"
        :aria-current-label="t('Current page')"
      />
    </article>
    <div class="flex gap-2 mt-2">
      <o-button variant="text" @click="emit('close-move-modal')">{{
        t("Cancel")
      }}</o-button>
      <o-button
        variant="primary"
        @click="updateResource"
        :disabled="moveDisabled"
        ><template v-if="resource.path === '/'">
          {{ t("Move resource to the root folder") }}
        </template>
        <template v-else
          >{{ t("Move resource to {folder}", { folder: resource.title }) }}
        </template></o-button
      >
    </div>
  </div>
</template>
<script lang="ts" setup>
import { useQuery } from "@vue/apollo-composable";
import { computed, reactive, ref, watch } from "vue";
import { GET_RESOURCE } from "../../graphql/resources";
import { IResource } from "../../types/resource";
import Folder from "vue-material-design-icons/Folder.vue";
import Link from "vue-material-design-icons/Link.vue";
import ChevronUp from "vue-material-design-icons/ChevronUp.vue";
import { useI18n } from "vue-i18n";

const props = defineProps<{ initialResource: IResource; username: string }>();
const emit = defineEmits(["update-resource", "close-move-modal"]);

const { t } = useI18n({ useScope: "global" });

const resourcePath = reactive<{
  path: string | undefined;
  username: string;
  id: string | undefined;
}>({
  id: props.initialResource.parent?.id,
  path: props.initialResource.parent?.path,
  username: props.username,
});

const RESOURCES_PER_PAGE = 10;
const page = ref(1);

const { result: resourceResult, refetch } = useQuery<{ resource: IResource }>(
  GET_RESOURCE,
  () => {
    if (resourcePath?.path) {
      return {
        path: resourcePath?.path,
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
    resourcePath.id = element.id;
    resourcePath.path = element.path;
    console.debug("Gone into folder", resourcePath);
  }
};

watch(props.initialResource, () => {
  if (props.initialResource) {
    resourcePath.id = props.initialResource?.parent?.id;
    resourcePath.path = props.initialResource?.parent?.path;
    refetch();
  }
});

const updateResource = (): void => {
  console.debug("Emitting updateResource from folder", resourcePath);
  const parent = resourcePath?.path === "/" ? null : resourcePath;
  emit(
    "update-resource",
    {
      id: props.initialResource.id,
      title: props.initialResource.title,
      parent: parent,
      path: parent?.path ?? "/",
    },
    props.initialResource.parent
  );
};

const moveDisabled = computed((): boolean | undefined => {
  return (
    (props.initialResource.parent &&
      resourcePath &&
      props.initialResource.parent.path === resourcePath.path) ||
    (props.initialResource.parent === undefined &&
      resourcePath &&
      resourcePath.path === "/")
  );
});

const goUp = () => {
  resourcePath.id = resource.value?.parent?.id;
  resourcePath.path = resource.value?.parent?.path;
};
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
