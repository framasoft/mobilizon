<template>
  <section class="container mx-auto">
    <breadcrumbs-nav
      v-if="group"
      :links="[
        {
          name: RouteName.MY_GROUPS,
          text: t('My groups'),
        },
        {
          name: RouteName.GROUP,
          params: { preferredUsername: usernameWithDomain(group) },
          text: displayName(group),
        },
        {
          name: RouteName.DISCUSSION_LIST,
          params: { preferredUsername: usernameWithDomain(group) },
          text: t('Discussions'),
        },
        {
          name: RouteName.CREATE_DISCUSSION,
          params: { preferredUsername: usernameWithDomain(group) },
          text: t('Create'),
        },
      ]"
    />
    <h1 class="title">{{ t("Create a discussion") }}</h1>

    <form @submit.prevent="createDiscussion">
      <o-field
        :label="t('Title')"
        label-for="discussion-title"
        :message="errors.title"
        :type="errors.title ? 'is-danger' : undefined"
      >
        <o-input
          aria-required="true"
          required
          v-model="discussion.title"
          id="discussion-title"
        />
      </o-field>

      <o-field :label="t('Text')">
        <Editor
          v-model="discussion.text"
          :aria-label="t('Message body')"
          v-if="currentActor"
          :current-actor="currentActor"
          :placeholder="t('Write a new message')"
        />
      </o-field>

      <o-button class="mt-2" native-type="submit">
        {{ t("Create the discussion") }}
      </o-button>
    </form>
  </section>
</template>

<script lang="ts" setup>
import { displayName, usernameWithDomain } from "@/types/actor";
import { CREATE_DISCUSSION } from "@/graphql/discussion";
import RouteName from "../../router/name";
import { computed, defineAsyncComponent, reactive, inject } from "vue";
import { useCurrentActorClient } from "@/composition/apollo/actor";
import { useGroup } from "@/composition/apollo/group";
import { useI18n } from "vue-i18n";
import { useMutation } from "@vue/apollo-composable";
import { IDiscussion } from "@/types/discussions";
import { useRouter } from "vue-router";
import { useHead } from "@vueuse/head";
import { Notifier } from "@/plugins/notifier";
import { AbsintheGraphQLError } from "@/types/errors.model";

const Editor = defineAsyncComponent(
  () => import("@/components/TextEditor.vue")
);

const props = defineProps<{ preferredUsername: string }>();

const { currentActor } = useCurrentActorClient();
const preferredUsername = computed(() => props.preferredUsername);

const { group } = useGroup(preferredUsername);

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => t("Create a discussion")),
});

const discussion = reactive({ title: "", text: "" });

const errors = reactive({ title: "" });

const router = useRouter();
const notifier = inject<Notifier>("notifier");

const { mutate, onDone, onError } = useMutation<{
  createDiscussion: IDiscussion;
}>(CREATE_DISCUSSION);

onDone(({ data }) => {
  router.push({
    name: RouteName.DISCUSSION,
    params: {
      id: data?.createDiscussion.id,
      slug: data?.createDiscussion.slug,
    },
  });
});

onError((error) => {
  console.error(error);
  if (error.graphQLErrors && error.graphQLErrors.length > 0) {
    const graphQLError = error.graphQLErrors[0] as AbsintheGraphQLError;
    if (graphQLError.field == "title") {
      errors.title = graphQLError.message;
    } else {
      notifier?.error(graphQLError.message);
    }
  }
});

const createDiscussion = async (): Promise<void> => {
  errors.title = "";
  if (!group.value?.id || !currentActor.value?.id) return;
  mutate({
    title: discussion.title,
    text: discussion.text,
    actorId: group.value.id,
  });
};
</script>

<style lang="scss" scoped>
.markdown-render h1 {
  font-size: 2em;
}
</style>
