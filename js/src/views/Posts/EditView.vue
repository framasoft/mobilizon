<template>
  <div>
    <form @submit.prevent="publish(false)" v-if="isCurrentActorAGroupModerator">
      <div class="container mx-auto">
        <breadcrumbs-nav v-if="actualGroup" :links="breadcrumbLinks" />
        <h1 v-if="isUpdate === true">
          {{ t("Edit post") }}
        </h1>
        <h1 v-else>
          {{ t("Add a new post") }}
        </h1>
        <h2>{{ t("General information") }}</h2>
        <picture-upload
          v-model="pictureFile"
          :textFallback="t('Headline picture')"
          :defaultImage="editablePost.picture"
        />

        <o-field
          :label="t('Title')"
          label-for="post-title"
          :type="errors.title ? 'is-danger' : null"
          :message="errors.title"
        >
          <o-input
            size="large"
            aria-required="true"
            required
            v-model="editablePost.title"
            id="post-title"
            dir="auto"
          />
        </o-field>

        <tag-input v-model="editablePost.tags" :fetch-tags="fetchTags" />

        <o-field :label="t('Post')">
          <p v-if="errors.body" class="help is-danger">{{ errors.body }}</p>
          <editor
            class="w-full"
            v-if="currentActor"
            v-model="editablePost.body"
            :aria-label="t('Post body')"
            :current-actor="currentActor"
            :placeholder="t('Write your post')"
          />
        </o-field>
        <h2 class="mt-2">{{ t("Who can view this post") }}</h2>
        <fieldset>
          <legend>
            {{
              t(
                "When the post is private, you'll need to share the link around."
              )
            }}
          </legend>
          <div class="field">
            <o-radio
              v-model="editablePost.visibility"
              name="postVisibility"
              :native-value="PostVisibility.PUBLIC"
              >{{ t("Visible everywhere on the web") }}</o-radio
            >
          </div>
          <div class="field">
            <o-radio
              v-model="editablePost.visibility"
              name="postVisibility"
              :native-value="PostVisibility.UNLISTED"
              >{{ t("Only accessible through link") }}</o-radio
            >
          </div>
          <div class="field">
            <o-radio
              v-model="editablePost.visibility"
              name="postVisibility"
              :native-value="PostVisibility.PRIVATE"
              >{{ t("Only accessible to members of the group") }}</o-radio
            >
          </div>
        </fieldset>
      </div>
      <nav class="navbar">
        <div class="container mx-auto">
          <div class="navbar-menu flex flex-wrap py-2">
            <div class="flex flex-wrap justify-end ml-auto gap-1">
              <o-button variant="text" @click="$router.go(-1)">{{
                t("Cancel")
              }}</o-button>
              <o-button
                v-if="isUpdate"
                variant="danger"
                outlined
                @click="openDeletePostModal"
                >{{ t("Delete post") }}</o-button
              >
              <!-- If an post has been published we can't make it draft anymore -->
              <o-button
                variant="primary"
                v-if="post?.draft === true"
                outlined
                @click="publish(true)"
                >{{ t("Save draft") }}</o-button
              >
              <o-button variant="primary" native-type="submit">
                <span v-if="isUpdate === false || post?.draft === true">{{
                  t("Publish")
                }}</span>

                <span v-else>{{ t("Update post") }}</span>
              </o-button>
            </div>
          </div>
        </div>
      </nav>
    </form>
    <o-loading
      v-else-if="postLoading"
      :is-full-page="false"
      v-model:active="postLoading"
      :can-cancel="false"
    ></o-loading>
    <div class="container mx-auto" v-else>
      <o-notification variant="danger">
        {{ t("Only group moderators can create, edit and delete posts.") }}
      </o-notification>
    </div>
  </div>
</template>
<script lang="ts" setup>
import {
  buildFileFromIMedia,
  buildFileVariable,
  readFileAsync,
} from "@/utils/image";
import { MemberRole, PostVisibility } from "@/types/enums";
import {
  CREATE_POST,
  DELETE_POST,
  FETCH_POST,
  UPDATE_POST,
} from "../../graphql/post";

import { IPost } from "../../types/post.model";
import Editor from "../../components/TextEditor.vue";
import { displayName, IActor, usernameWithDomain } from "../../types/actor";
import TagInput from "../../components/Event/TagInput.vue";
import RouteName from "../../router/name";
import PictureUpload from "../../components/PictureUpload.vue";
import { useGroup } from "@/composition/apollo/group";
import {
  useCurrentActorClient,
  usePersonStatusGroup,
} from "@/composition/apollo/actor";
import { useHead } from "@vueuse/head";
import { useI18n } from "vue-i18n";
import { computed, inject, onMounted, ref, watch } from "vue";
import { useRouter } from "vue-router";
import { useMutation, useQuery } from "@vue/apollo-composable";
import { fetchTags } from "@/composition/apollo/tags";
import { Dialog } from "@/plugins/dialog";

const props = withDefaults(
  defineProps<{
    slug?: string;
    preferredUsername?: string;
    isUpdate?: boolean;
  }>(),
  { isUpdate: false }
);

const { currentActor } = useCurrentActorClient();
const { group } = useGroup(props.preferredUsername);

const { result: postResult, loading: postLoading } = useQuery<{
  post: IPost;
}>(FETCH_POST, () => ({ slug: props.slug }));

const post = computed(() => postResult.value?.post);

const pictureFile = ref<File | null>(null);
const errors = ref<Record<string, unknown>>({});
const editablePost = ref<IPost>({
  title: "",
  body: "",
  local: true,
  draft: true,
  visibility: PostVisibility.PUBLIC,
  tags: [],
});

onMounted(async () => {
  pictureFile.value = await buildFileFromIMedia(post.value?.picture);
});

watch(post, async (newPost: IPost | undefined, oldPost: IPost | undefined) => {
  if (oldPost?.picture !== newPost?.picture) {
    pictureFile.value = await buildFileFromIMedia(post.value?.picture);
  }
  if (newPost) {
    editablePost.value = { ...newPost };
  }
});

const router = useRouter();

const { mutate: updatePost, onDone: onUpdateDone } = useMutation<{
  updatePost: IPost;
}>(UPDATE_POST);
const {
  mutate: createPost,
  onDone: onCreateDone,
  onError: onCreateError,
} = useMutation<{
  createPost: IPost;
}>(CREATE_POST);

onUpdateDone(({ data }) => {
  if (data && data.updatePost) {
    router.push({
      name: RouteName.POST,
      params: { slug: data.updatePost.slug },
    });
  }
});

onCreateDone(({ data }) => {
  if (data && data.createPost) {
    router.push({
      name: RouteName.POST,
      params: { slug: data.createPost.slug },
    });
  }
});

onCreateError((error) => {
  console.error(error);
  errors.value = error.graphQLErrors.reduce(
    (acc: { [key: string]: any }, localError: any) => {
      acc[localError.field] = transformMessage(localError.message);
      return acc;
    },
    {}
  );
});

const publish = async (draft: boolean): Promise<void> => {
  errors.value = {};

  if (props.isUpdate) {
    updatePost({
      id: editablePost.value?.id,
      title: editablePost.value?.title,
      body: editablePost.value?.body,
      tags: (editablePost.value?.tags || []).map(({ title }) => title),
      visibility: editablePost.value?.visibility,
      draft,
      ...(await buildPicture()),
    });
  } else {
    createPost({
      ...editablePost.value,
      ...(await buildPicture()),
      tags: (editablePost.value?.tags ?? []).map(({ title }) => title),
      attributedToId: actualGroup.value.id,
      draft,
    });
  }
};

const transformMessage = (message: string[] | string): string | undefined => {
  if (Array.isArray(message) && message.length > 0) {
    return message[0];
  }
  if (typeof message === "string") {
    return message;
  }
  return undefined;
};

const buildPicture = async (): Promise<Record<string, unknown>> => {
  let obj: { picture?: any } = {};
  if (pictureFile.value) {
    const pictureObj = buildFileVariable(pictureFile.value, "picture");
    obj = { ...obj, ...pictureObj };
  }
  try {
    if (editablePost.value?.picture && pictureFile.value) {
      const oldPictureFile = (await buildFileFromIMedia(
        editablePost.value.picture
      )) as File;
      const oldPictureFileContent = await readFileAsync(oldPictureFile);
      const newPictureFileContent = await readFileAsync(
        pictureFile.value as File
      );
      if (oldPictureFileContent === newPictureFileContent) {
        obj.picture = { mediaId: editablePost.value.picture.id };
      }
    }
  } catch (e: any) {
    console.error(e);
  }
  return obj;
};

const actualGroup = computed((): IActor => {
  if (!group.value?.id) {
    return post.value?.attributedTo as IActor;
  }
  return group.value;
});

const actualPreferredUsername = computed(() =>
  usernameWithDomain(actualGroup.value)
);

const { t } = useI18n({ useScope: "global" });

const breadcrumbLinks = computed(() => {
  const links = [
    {
      name: RouteName.GROUP,
      params: {
        preferredUsername: usernameWithDomain(actualGroup.value),
      },
      text: displayName(actualGroup.value),
    },
    {
      name: RouteName.POSTS,
      params: {
        preferredUsername: usernameWithDomain(actualGroup.value),
      },
      text: t("Posts"),
    },
  ];
  if (props.preferredUsername) {
    links.push({
      text: t("New post") as string,
      name: RouteName.POST_EDIT,
      params: { preferredUsername: usernameWithDomain(actualGroup.value) },
    });
  } else {
    links.push({
      text: t("Edit post") as string,
      name: RouteName.POST_EDIT,
      params: { preferredUsername: usernameWithDomain(actualGroup.value) },
    });
  }
  return links;
});

const isCurrentActorAGroupModerator = computed((): boolean => {
  return hasCurrentActorThisRole([
    MemberRole.MODERATOR,
    MemberRole.ADMINISTRATOR,
  ]);
});

const hasCurrentActorThisRole = (givenRole: string | string[]): boolean => {
  const roles = Array.isArray(givenRole) ? givenRole : [givenRole];
  return (
    personMemberships.value?.total > 0 &&
    roles.includes(personMemberships.value?.elements[0].role)
  );
};

const { person } = usePersonStatusGroup(actualPreferredUsername);

const personMemberships = computed(
  () => person.value?.memberships ?? { total: 0, elements: [] }
);

const dialog = inject<Dialog>("dialog");

const openDeletePostModal = async (): Promise<void> => {
  dialog?.confirm({
    variant: "danger",
    title: t("Delete post"),
    message: t(
      "Are you sure you want to delete this post? This action cannot be reverted."
    ),
    onConfirm: () =>
      deletePost({
        id: post.value?.id,
      }),
  });
};

const { mutate: deletePost, onDone: onDeletePostDone } =
  useMutation(DELETE_POST);

onDeletePostDone(({ data }) => {
  if (data && post.value?.attributedTo) {
    router.push({
      name: RouteName.POSTS,
      params: {
        preferredUsername: usernameWithDomain(post.value?.attributedTo),
      },
    });
  }
});

useHead({
  title: computed(() =>
    props.isUpdate ? t("Edit post") : t("Add a new post")
  ),
});
</script>
