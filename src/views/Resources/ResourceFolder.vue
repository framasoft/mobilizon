<template>
  <div class="container mx-auto" v-if="resource">
    <breadcrumbs-nav :links="breadcrumbLinks">
      <li>
        <o-dropdown aria-role="list">
          <template #trigger>
            <o-button variant="primary">+</o-button>
          </template>

          <o-dropdown-item aria-role="listitem" @click="createFolderModal">
            <Folder />
            {{ t("New folder") }}
          </o-dropdown-item>
          <o-dropdown-item aria-role="listitem" @click="createLinkModal">
            <Link />
            {{ t("New link") }}
          </o-dropdown-item>
          <hr
            role="presentation"
            class="dropdown-divider"
            v-if="resourceProviders?.length"
          />
          <o-dropdown-item
            aria-role="listitem"
            v-for="resourceProvider in resourceProviders"
            :key="resourceProvider.software"
            @click="createResourceFromProvider(resourceProvider)"
          >
            <o-icon :icon="mapServiceTypeToIcon[resourceProvider.software]" />
            {{ createSentenceForType(resourceProvider.software) }}
          </o-dropdown-item>
        </o-dropdown>
      </li>
    </breadcrumbs-nav>
    <DraggableList
      v-if="resource.actor"
      :resources="resource.children.elements"
      :isRoot="resource.path === '/'"
      :group="resource.actor"
      @delete="
        (resourceID: string) =>
          deleteResource({
            id: resourceID,
          })
      "
      @update="updateResource"
      @rename="handleRename"
      @move="handleMove"
    />
    <o-pagination
      v-if="resource.children.total > RESOURCES_PER_PAGE"
      :total="resource.children.total"
      v-model:current="page"
      :per-page="RESOURCES_PER_PAGE"
      :aria-next-label="t('Next page')"
      :aria-previous-label="t('Previous page')"
      :aria-page-label="t('Page')"
      :aria-current-label="t('Current page')"
    >
    </o-pagination>
    <o-modal
      v-model:active="renameModal"
      has-modal-card
      :close-button-aria-label="t('Close')"
    >
      <div class="w-full md:w-[640px]">
        <section>
          <form @submit.prevent="renameResource">
            <o-field :label="t('Title')">
              <o-input
                ref="resourceRenameInput"
                aria-required="true"
                v-model="updatedResource.title"
                expanded
              />
            </o-field>

            <o-button native-type="submit">{{ t("Rename resource") }}</o-button>
          </form>
        </section>
      </div>
    </o-modal>
    <o-modal
      v-model:active="moveModal"
      has-modal-card
      :close-button-aria-label="t('Close')"
    >
      <div class="w-full">
        <section>
          <resource-selector
            :initialResource="updatedResource"
            :username="usernameWithDomain(resource.actor)"
            @update-resource="moveResource"
            @close-move-modal="moveModal = false"
          />
        </section>
      </div>
    </o-modal>
    <o-modal
      v-model:active="createResourceModal"
      has-modal-card
      :close-button-aria-label="t('Close')"
      :autoFocus="false"
    >
      <section class="w-full md:w-[640px]">
        <o-notification variant="danger" v-if="modalError">
          {{ modalError }}
        </o-notification>
        <form @submit.prevent="createResource">
          <p v-if="newResource.type === 'pad'">
            {{
              t("The pad will be created on {service}", {
                service: newResourceHost,
              })
            }}
          </p>
          <p v-else-if="newResource.type === 'calc'">
            {{
              t("The calc will be created on {service}", {
                service: newResourceHost,
              })
            }}
          </p>
          <p v-else-if="newResource.type === 'visio'">
            {{
              t("The videoconference will be created on {service}", {
                service: newResourceHost,
              })
            }}
          </p>
          <o-field :label="t('Title')" label-for="new-resource-title">
            <o-input
              ref="modalNewResourceInput"
              aria-required="true"
              v-model="newResource.title"
              id="new-resource-title"
              expanded
            />
          </o-field>

          <o-button class="mt-2" native-type="submit">{{
            createResourceButtonLabel
          }}</o-button>
        </form>
      </section>
    </o-modal>
    <o-modal
      v-model:active="createLinkResourceModal"
      has-modal-card
      aria-modal
      :close-button-aria-label="t('Close')"
      :autoFocus="false"
      :width="640"
    >
      <div class="w-full md:w-[640px]">
        <section class="p-10">
          <o-notification variant="danger" v-if="modalError">
            {{ modalError }}
          </o-notification>
          <form @submit.prevent="createResource">
            <o-field
              expanded
              :label="t('URL')"
              label-for="new-resource-url"
              :variant="modalFieldErrors['resource_url'] ? 'danger' : undefined"
              :message="modalFieldErrors['resource_url']"
            >
              <o-input
                id="new-resource-url"
                type="url"
                required
                expanded
                v-model="newResource.resourceUrl"
                @blur="previewResource"
                ref="modalNewResourceLinkInput"
              />
            </o-field>

            <div class="new-resource-preview" v-if="newResource.title">
              <resource-item :resource="newResource" :preview="true" />
            </div>

            <o-field
              :label="t('Title')"
              label-for="new-resource-link-title"
              :variant="modalFieldErrors['title'] ? 'danger' : undefined"
              :message="modalFieldErrors['title']"
            >
              <o-input
                aria-required="true"
                v-model="newResource.title"
                id="new-resource-link-title"
                expanded
              />
            </o-field>

            <o-field
              :label="t('Description')"
              label-for="new-resource-summary"
              :variant="modalFieldErrors['summary'] ? 'danger' : undefined"
              :message="modalFieldErrors['summary']"
            >
              <o-input
                type="textarea"
                v-model="newResource.summary"
                id="new-resource-summary"
                expanded
              />
            </o-field>

            <o-button native-type="submit" class="mt-2">{{
              t("Create resource")
            }}</o-button>
          </form>
        </section>
      </div>
    </o-modal>
  </div>
</template>
<script lang="ts" setup>
import ResourceItem from "@/components/Resource/ResourceItem.vue";
import { displayName, usernameWithDomain } from "@/types/actor";
import RouteName from "@/router/name";
import {
  IResource,
  mapServiceTypeToIcon,
  IProvider,
  IResourceMetadata,
} from "@/types/resource";
import {
  CREATE_RESOURCE,
  DELETE_RESOURCE,
  PREVIEW_RESOURCE_LINK,
  GET_RESOURCE,
  UPDATE_RESOURCE,
} from "@/graphql/resources";
import ResourceSelector from "@/components/Resource/ResourceSelector.vue";
import {
  ApolloCache,
  FetchResult,
  InternalRefetchQueriesInclude,
} from "@apollo/client/core";
import { useMutation, useQuery } from "@vue/apollo-composable";
import { computed, nextTick, reactive, ref, watch } from "vue";
import { useI18n } from "vue-i18n";
import { integerTransformer, useRouteQuery } from "vue-use-route-query";
import { useRouter } from "vue-router";
import { useHead } from "@unhead/vue";
import { useResourceProviders } from "@/composition/apollo/config";
import Folder from "vue-material-design-icons/Folder.vue";
import Link from "vue-material-design-icons/Link.vue";
import DraggableList from "@/components/Resource/DraggableList.vue";
import { resourcePathArray } from "@/components/Resource/utils";
import {
  AbsintheGraphQLError,
  AbsintheGraphQLErrors,
} from "@/types/errors.model";

const RESOURCES_PER_PAGE = 10;
const page = useRouteQuery("page", 1, integerTransformer);

const props = defineProps<{
  path: string | string[];
  preferredUsername: string;
}>();

const {
  result: resourceResult,
  onError: onGetResourceError,
  fetchMore,
} = useQuery<{
  resource: IResource;
}>(GET_RESOURCE, () => {
  let path = Array.isArray(props.path) ? props.path.join("/") : props.path;
  path = path[0] !== "/" ? `/${path}` : path;
  return {
    path,
    username: props.preferredUsername,
    page: page.value,
    limit: RESOURCES_PER_PAGE,
  };
});

const resource = computed(() => resourceResult.value?.resource);

onGetResourceError(({ graphQLErrors }) => {
  handleErrors(graphQLErrors);
});

const { resourceProviders } = useResourceProviders();

const { t } = useI18n({ useScope: "global" });

// config: CONFIG,

const newResource = reactive<IResource>({
  title: "",
  summary: "",
  resourceUrl: "",
  children: { elements: [], total: 0 },
  metadata: {},
  type: "link",
});

const updatedResource = ref<IResource>({
  title: "",
  resourceUrl: "",
  metadata: {},
  children: { elements: [], total: 0 },
  path: undefined,
});

const createResourceModal = ref(false);
const createLinkResourceModal = ref(false);
const moveModal = ref(false);
const renameModal = ref(false);
const modalError = ref("");
const modalFieldErrors: Record<string, string> = reactive({});

const resourceRenameInput = ref<any>();
const modalNewResourceInput = ref<{
  $refs: { inputRef: HTMLInputElement };
} | null>();
const modalNewResourceLinkInput = ref<{
  $refs: { inputRef: HTMLInputElement };
} | null>();

const actualPath = computed((): string => {
  const path = Array.isArray(props.path) ? props.path.join("/") : props.path;
  return path[0] !== "/" ? `/${path}` : path;
});

const filteredPath = computed((): string[] => {
  if (resource.value?.path !== "/") {
    return resourcePathArray(resource.value);
  }
  return [];
});

const isRoot = computed((): boolean => {
  return actualPath.value === "/";
});

const lastFragment = computed((): string | undefined => {
  return filteredPath.value.slice(-1)[0];
});

const {
  mutate: createResourceMutation,
  onDone: createResourceDone,
  onError: createResourceError,
} = useMutation(CREATE_RESOURCE, () => ({
  refetchQueries: () => postRefreshQueries(),
}));

createResourceDone(() => {
  createLinkResourceModal.value = false;
  createResourceModal.value = false;
  newResource.title = "";
  newResource.summary = "";
  newResource.resourceUrl = "";
});

createResourceError((err) => {
  console.error(err);
  const error = err.graphQLErrors[0] as AbsintheGraphQLError;
  if (error.field) {
    modalFieldErrors[error.field] = (error.message as unknown as string[]).join(
      ","
    );
  } else {
    modalError.value = (error.message as unknown as string[]).join(",");
  }
});

const createResource = () => {
  if (!resource.value?.actor) return;
  modalError.value = "";
  createResourceMutation({
    title: newResource.title,
    summary: newResource.summary,
    actorId: resource.value.actor?.id,
    resourceUrl: newResource.resourceUrl,
    parentId: resource.value?.id?.startsWith("root_")
      ? null
      : resource.value?.id,
    type: newResource.type,
  });
};

const {
  mutate: previewResourceLinkMutation,
  onDone: previewDone,
  onError: previewError,
} = useMutation<{ previewResourceLink: IResourceMetadata }>(
  PREVIEW_RESOURCE_LINK
);

previewDone(({ data }) => {
  if (!data?.previewResourceLink) return;
  newResource.title = data?.previewResourceLink.title ?? "";
  newResource.summary = data?.previewResourceLink?.description?.substring(
    0,
    390
  );
  newResource.metadata = data?.previewResourceLink;
  newResource.type = "link";
});

previewError((err) => {
  console.error(err);
  const error = err.graphQLErrors[0] as AbsintheGraphQLError;
  if (error.field) {
    modalFieldErrors[error.field] = error.message;
  } else {
    modalError.value = err.graphQLErrors[0].message;
  }
});

const previewResource = async (): Promise<void> => {
  modalError.value = "";
  if (newResource.resourceUrl === "") return;
  previewResourceLinkMutation({
    resourceUrl: newResource.resourceUrl,
  });
};

const createSentenceForType = (type: string): string => {
  switch (type) {
    case "folder":
      return t("Create a folder") as string;
    case "pad":
      return t("Create a pad") as string;
    case "calc":
      return t("Create a calc") as string;
    case "visio":
      return t("Create a videoconference") as string;
    default:
      return "";
  }
};

const createLinkModal = async (): Promise<void> => {
  createLinkResourceModal.value = true;
  await nextTick();
  modalNewResourceLinkInput.value?.$refs.inputRef?.focus();
};

const createFolderModal = async (): Promise<void> => {
  newResource.type = "folder";
  createResourceModal.value = true;
  await nextTick();
  modalNewResourceInput.value?.$refs.inputRef?.focus();
};

const createResourceFromProvider = async (
  provider: IProvider
): Promise<void> => {
  newResource.resourceUrl = generateFullResourceUrl(provider);
  newResource.type = provider.software;
  createResourceModal.value = true;
  await nextTick();
  modalNewResourceInput.value?.$refs.inputRef?.focus();
};

const generateFullResourceUrl = (provider: IProvider): string => {
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
};

const createResourceButtonLabel = computed((): string => {
  if (!newResource.type) return "";
  return createSentenceForType(newResource.type);
});

// eslint-disable-next-line class-methods-use-this
const postRefreshQueries = (): InternalRefetchQueriesInclude => {
  return [
    {
      query: GET_RESOURCE,
      variables: {
        path: actualPath.value,
        username: props.preferredUsername,
        page: page.value,
        limit: RESOURCES_PER_PAGE,
      },
    },
  ];
};

const { mutate: deleteResource, onError: onDeleteResourceError } = useMutation(
  DELETE_RESOURCE,
  () => ({
    refetchQueries: () => postRefreshQueries(),
  })
);

onDeleteResourceError((e) => console.error(e));

const handleRename = async (resourceToRename: IResource): Promise<void> => {
  renameModal.value = true;
  updatedResource.value = { ...resourceToRename };
  await nextTick();
  resourceRenameInput.value?.$el.focus();
  resourceRenameInput.value?.$el.querySelector("input")?.select();
};

const handleMove = (resourceToMove: IResource): void => {
  moveModal.value = true;
  updatedResource.value = { ...resourceToMove };
};

const moveResource = async (
  resourceToMove: IResource,
  oldParent: IResource | undefined
): Promise<void> => {
  const parentPath = oldParent && oldParent.path ? oldParent.path || "/" : "/";
  await updateResource(resourceToMove, parentPath);
  moveModal.value = false;
};

const renameResource = async (): Promise<void> => {
  await updateResource(updatedResource.value);
  renameModal.value = false;
};

const { mutate: updateResourceMutation } = useMutation<{
  updateResource: IResource;
}>(UPDATE_RESOURCE, () => ({
  refetchQueries: () => postRefreshQueries(),
  update: (
    store: ApolloCache<{ updateResource: IResource }>,
    { data }: FetchResult,
    { context }
  ) => {
    const parentPath = context?.parentPath;
    if (!data || data.updateResource == null || parentPath == null) return;
    if (!resource.value?.actor) return;

    console.debug("Removing ressource from old parent");
    const oldParentCachedData = store.readQuery<{ resource: IResource }>({
      query: GET_RESOURCE,
      variables: {
        path: parentPath,
        username: resource.value.actor.preferredUsername,
      },
    });
    if (oldParentCachedData == null) return;
    const { resource: oldParentCachedResource } = oldParentCachedData;
    if (oldParentCachedResource == null) {
      console.error("Cannot update resource cache, because of null value.");
      return;
    }
    const postUpdatedResource: IResource = data.updateResource;

    const updatedElementList = oldParentCachedResource.children.elements.filter(
      (cachedResource) => cachedResource.id !== postUpdatedResource.id
    );

    store.writeQuery({
      query: GET_RESOURCE,
      variables: {
        path: parentPath,
        username: resource.value.actor.preferredUsername,
      },
      data: {
        resource: {
          ...oldParentCachedResource,
          children: {
            ...oldParentCachedResource.children,
            elements: [...updatedElementList],
          },
        },
      },
    });
    console.debug("Finished removing ressource from old parent");

    console.debug("Adding resource to new parent");
    if (!postUpdatedResource.parent || !postUpdatedResource.parent.path) {
      console.debug("No cache found for new parent");
      return;
    }
    const newParentCachedData = store.readQuery<{ resource: IResource }>({
      query: GET_RESOURCE,
      variables: {
        path: postUpdatedResource.parent.path,
        username: resource.value.actor.preferredUsername,
      },
    });
    if (newParentCachedData == null) return;
    const { resource: newParentCachedResource } = newParentCachedData;
    if (newParentCachedResource == null) {
      console.error("Cannot update resource cache, because of null value.");
      return;
    }

    store.writeQuery({
      query: GET_RESOURCE,
      variables: {
        path: postUpdatedResource.parent.path,
        username: resource.value.actor.preferredUsername,
      },
      data: {
        resource: {
          ...newParentCachedResource,
          children: {
            ...newParentCachedResource.children,
            elements: [...newParentCachedResource.children.elements, resource],
          },
        },
      },
    });
    console.debug("Finished adding resource to new parent");
  },
}));

const updateResource = async (
  resourceToUpdate: IResource,
  parentPath: string | null = null
): Promise<void> => {
  console.debug(
    `Update resource « ${resourceToUpdate.title} » at path ${resourceToUpdate.path}`
  );
  updateResourceMutation(
    {
      id: resourceToUpdate.id,
      title: resourceToUpdate.title,
      parentId: resourceToUpdate.parent ? resourceToUpdate.parent.id : null,
      path: resourceToUpdate.path,
    },
    { context: { parentPath } }
  );
};

watch(page, () => {
  fetchMore({
    // New variables
    variables: {
      page: page.value,
      limit: RESOURCES_PER_PAGE,
    },
  });
});

const router = useRouter();

const handleErrors = (errors: AbsintheGraphQLErrors): void => {
  if (errors.some((error) => error.status_code === 404)) {
    router.replace({ name: RouteName.PAGE_NOT_FOUND });
  }
};

const breadcrumbLinks = computed(() => {
  if (!resource.value?.actor) return [];
  const resourceActor = resource.value.actor;
  const links = [
    {
      name: RouteName.GROUP,
      params: { preferredUsername: usernameWithDomain(resource.value.actor) },
      text: displayName(resource.value.actor),
    },
    {
      name: RouteName.RESOURCE_FOLDER_ROOT,
      params: { preferredUsername: usernameWithDomain(resource.value.actor) },
      text: t("Resources") as string,
    },
  ];

  links.push(
    ...filteredPath.value.map((pathFragment, index) => {
      return {
        name: RouteName.RESOURCE_FOLDER,
        params: {
          path: resourcePathArray(resource.value).slice(
            0,
            index + 1
          ) as unknown as string,
          preferredUsername: usernameWithDomain(resourceActor),
        },
        text: pathFragment,
      };
    })
  );
  return links;
});

const newResourceHost = computed(() => {
  if (!newResource.resourceUrl) return;
  return new URL(newResource.resourceUrl).host;
});

useHead({
  title: computed(() =>
    isRoot.value
      ? t("Resources")
      : t("{folder} - Resources", {
          folder: lastFragment.value,
        })
  ),
});
</script>
<style lang="scss" scoped>
@use "@/styles/_mixins" as *;

nav.breadcrumb ul {
  align-items: center;

  li:last-child .dropdown {
    @include margin-left(5px);

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

    :deep(.b-checkbox.checkbox) {
      @include margin-left(10px);
    }

    .actions {
      @include margin-right(5px);

      & > * {
        @include margin-left(5px);
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
  // color: #444b5d;
  margin-top: 14px;
  margin-bottom: 14px;

  .resource-checkbox {
    align-self: center;
    @include padding-left(10px);
    opacity: 0.3;

    :deep(.b-checkbox.checkbox) {
      @include margin-right(0.25rem);
    }
  }

  &:hover .resource-checkbox,
  .resource-checkbox.checked {
    opacity: 1;
  }
}
</style>
