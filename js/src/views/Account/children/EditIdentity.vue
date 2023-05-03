<template>
  <div>
    <breadcrumbs-nav :links="breadcrumbsLinks" />
    <div v-if="identity">
      <h1>
        <span v-if="isUpdate" class="line-clamp-2">{{
          displayName(identity)
        }}</span>
        <span v-else>{{ $t("I create an identity") }}</span>
      </h1>

      <picture-upload
        v-model="avatarFile"
        :defaultImage="identity.avatar"
        :maxSize="avatarMaxSize"
        class="picture-upload"
      />

      <o-field
        horizontal
        :label="$t('Display name')"
        label-for="identity-display-name"
      >
        <o-input
          aria-required="true"
          required
          v-model="identity.name"
          @input="(event) => updateUsername(event.target.value)"
          id="identity-display-name"
          dir="auto"
        />
      </o-field>

      <o-field
        horizontal
        custom-class="username-field"
        expanded
        :label="$t('Username')"
        label-for="identity-username"
        :message="message"
      >
        <o-field expanded>
          <o-input
            aria-required="true"
            required
            v-model="identity.preferredUsername"
            :disabled="isUpdate"
            dir="auto"
            :use-html5-validation="!isUpdate"
            pattern="[a-z0-9_]+"
            id="identity-username"
          />

          <p class="control">
            <span class="button is-static">@{{ getInstanceHost }}</span>
          </p>
        </o-field>
      </o-field>

      <o-field
        horizontal
        :label="$t('Description')"
        label-for="identity-summary"
      >
        <o-input
          type="textarea"
          dir="auto"
          aria-required="false"
          v-model="identity.summary"
          id="identity-summary"
        />
      </o-field>

      <o-notification
        variant="danger"
        has-icon
        aria-close-label="Close notification"
        role="alert"
        :key="error"
        v-for="error in errors"
        >{{ error }}</o-notification
      >

      <o-field class="submit">
        <div class="control">
          <o-button type="button" variant="primary" @click="submit()">
            {{ $t("Save") }}
          </o-button>
        </div>
      </o-field>

      <o-field class="delete-identity">
        <o-button
          v-if="isUpdate"
          @click="openDeleteIdentityConfirmation()"
          variant="text"
        >
          {{ $t("Delete this identity") }}
        </o-button>
      </o-field>

      <section v-if="isUpdate">
        <h2>{{ $t("Profile feeds") }}</h2>
        <p>
          {{
            $t(
              "These feeds contain event data for the events for which this specific profile is a participant or creator. You should keep these private. You can find feeds for all of your profiles into your notification settings."
            )
          }}
        </p>
        <div v-if="identity.feedTokens && identity.feedTokens.length > 0">
          <div
            class="flex flex-wrap gap-2"
            v-for="feedToken in identity.feedTokens"
            :key="feedToken.token"
          >
            <o-tooltip
              :label="$t('URL copied to clipboard')"
              :active="showCopiedTooltip.atom"
              always
              variant="success"
              position="left"
            >
              <o-button
                tag="a"
                icon-left="rss"
                @click="
                  (e: Event) => copyURL(e, tokenToURL(feedToken.token, 'atom'), 'atom')
                "
                :href="tokenToURL(feedToken.token, 'atom')"
                target="_blank"
                >{{ $t("RSS/Atom Feed") }}</o-button
              >
            </o-tooltip>
            <o-tooltip
              :label="$t('URL copied to clipboard')"
              :active="showCopiedTooltip.ics"
              always
              variant="success"
              position="left"
            >
              <o-button
                tag="a"
                @click="
                  (e: Event) => copyURL(e, tokenToURL(feedToken.token, 'ics'), 'ics')
                "
                icon-left="calendar-sync"
                :href="tokenToURL(feedToken.token, 'ics')"
                target="_blank"
                >{{ $t("ICS/WebCal Feed") }}</o-button
              >
            </o-tooltip>
            <o-button
              icon-left="refresh"
              variant="text"
              @click="openRegenerateFeedTokensConfirmation"
              >{{ $t("Regenerate new links") }}</o-button
            >
          </div>
        </div>
        <div v-else>
          <o-button
            icon-left="refresh"
            variant="text"
            @click="generateFeedTokens"
            >{{ $t("Create new links") }}</o-button
          >
        </div>
      </section>
    </div>
  </div>
</template>

<style scoped lang="scss">
@use "@/styles/_mixins" as *;
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

.username-field + .field {
  margin-bottom: 0;
}

:deep(.buttons > *:not(:last-child) .button) {
  @include margin-right(0.5rem);
}
</style>

<script lang="ts" setup>
import {
  CREATE_PERSON,
  DELETE_PERSON,
  FETCH_PERSON,
  IDENTITIES,
  PERSON_FRAGMENT,
  PERSON_FRAGMENT_FEED_TOKENS,
  UPDATE_PERSON,
} from "@/graphql/actor";
import { IPerson, displayName } from "@/types/actor";
import PictureUpload from "@/components/PictureUpload.vue";
import { MOBILIZON_INSTANCE_HOST } from "@/api/_entrypoint";
import RouteName from "@/router/name";
import { buildFileVariable } from "@/utils/image";
import { changeIdentity } from "@/utils/identity";
import {
  CREATE_FEED_TOKEN_ACTOR,
  DELETE_FEED_TOKEN,
} from "@/graphql/feed_tokens";
import { IFeedToken } from "@/types/feedtoken.model";
import { ServerParseError } from "@apollo/client/link/http";
import { ApolloCache, FetchResult, InMemoryCache } from "@apollo/client/core";
import pick from "lodash/pick";
import { ActorType } from "@/types/enums";
import { useRouter } from "vue-router";
import { useCurrentActorClient } from "@/composition/apollo/actor";
import { useMutation, useQuery, useApolloClient } from "@vue/apollo-composable";
import { useAvatarMaxSize } from "@/composition/config";
import { computed, inject, reactive, ref, watch } from "vue";
import { useI18n } from "vue-i18n";
import { convertToUsername } from "@/utils/username";
import { Dialog } from "@/plugins/dialog";
import { Notifier } from "@/plugins/notifier";
import { AbsintheGraphQLErrors } from "@/types/errors.model";
import { ICurrentUser } from "@/types/current-user.model";

const { t } = useI18n({ useScope: "global" });
const router = useRouter();

const props = defineProps<{ isUpdate: boolean; identityName?: string }>();

const { currentActor } = useCurrentActorClient();

const { result: personResult, onError: onPersonError } = useQuery<{
  fetchPerson: IPerson;
}>(
  FETCH_PERSON,
  () => ({
    username: props.identityName,
  }),
  () => ({
    enabled: props.identityName !== undefined,
  })
);

onPersonError((err) => handleErrors(err as unknown as AbsintheGraphQLErrors));

const person = computed(() => personResult.value?.fetchPerson);

const baseIdentity: IPerson = {
  id: undefined,
  avatar: null,
  name: "",
  preferredUsername: "",
  summary: "",
  feedTokens: [],
  url: "",
  domain: null,
  type: ActorType.PERSON,
  suspended: false,
};

const identity = ref(baseIdentity);

watch(person, () => {
  console.debug("person changed", person.value);
  if (person.value) {
    identity.value = person.value;
  }
});

const avatarMaxSize = useAvatarMaxSize();

// error({ graphQLErrors }) {
//   this.handleErrors(graphQLErrors);
// },
// metaInfo() {
//   // eslint-disable-next-line @typescript-eslint/ban-ts-comment
//   // @ts-ignore
//   const { isUpdate, identityName } = this;
//   let title = t("Create a new profile") as string;
//   if (isUpdate) {
//     title = t("Edit profile {profile}", {
//       profile: identityName,
//     }) as string;
//   }
//   return {
//     title,
//   };
// },

const errors = ref<string[]>([]);
const avatarFile = ref<File | null>(null);
const showCopiedTooltip = reactive({ ics: false, atom: false });

const isUpdate = computed(() => props.isUpdate);
const identityName = computed(() => props.identityName);

const message = computed((): string | null => {
  if (props.isUpdate) return null;
  return t(
    "Only alphanumeric lowercased characters and underscores are supported."
  );
});

watch(isUpdate, () => {
  resetFields();
});

watch(identityName, async () => {
  // Only used when we update the identity
  if (!isUpdate.value) {
    identity.value = baseIdentity;
    return;
  }

  await redirectIfNoIdentitySelected(identityName.value);

  if (!identityName.value) {
    router.push({ name: "CreateIdentity" });
  }

  if (identityName.value && identity.value) {
    avatarFile.value = null;
  }
});

const submit = (): Promise<void> => {
  if (props.isUpdate) return updateIdentity();

  return createIdentity();
};

const {
  mutate: deletePersonMutation,
  onDone: deletePersonDone,
  onError: deletePersonError,
} = useMutation(DELETE_PERSON, () => ({
  update: (store: ApolloCache<InMemoryCache>) => {
    const data = store.readQuery<{ loggedUser: Pick<ICurrentUser, "actors"> }>({
      query: IDENTITIES,
    });

    if (data) {
      store.writeQuery({
        query: IDENTITIES,
        data: {
          loggedUser: {
            ...data.loggedUser,
            actors: data.loggedUser.actors.filter(
              (i) => i.id !== identity.value.id
            ),
          },
        },
      });
    }
  },
}));

const notifier = inject<Notifier>("notifier");

const { resolveClient } = useApolloClient();

deletePersonDone(async () => {
  notifier?.success(
    t("Identity {displayName} deleted", {
      displayName: displayName(identity.value),
    })
  );
  /**
   * If we just deleted the current identity,
   * we need to change it to the next one
   */
  const client = resolveClient();
  const data = client.readQuery<{
    loggedUser: Pick<ICurrentUser, "actors">;
  }>({ query: IDENTITIES });
  if (data) {
    await maybeUpdateCurrentActorCache(data.loggedUser.actors[0]);
  }

  await redirectIfNoIdentitySelected();
});

deletePersonError((err) => handleError(err));

/**
 * Delete an identity
 */
const deleteIdentity = async (): Promise<void> => {
  deletePersonMutation({
    id: identity.value?.id,
  });
};

const {
  mutate: updateIdentityMutation,
  onDone: updateIdentityDone,
  onError: updateIdentityError,
} = useMutation(UPDATE_PERSON, () => ({
  update: (
    store: ApolloCache<InMemoryCache>,
    { data: updateData }: FetchResult
  ) => {
    const data = store.readQuery<{ loggedUser: Pick<ICurrentUser, "actors"> }>({
      query: IDENTITIES,
    });

    if (data && updateData?.updatePerson) {
      maybeUpdateCurrentActorCache(updateData?.updatePerson);

      store.writeFragment({
        fragment: PERSON_FRAGMENT,
        id: `Person:${updateData?.updatePerson.id}`,
        data: {
          ...updateData?.updatePerson,
          type: ActorType.PERSON,
        },
      });
    }
  },
}));

updateIdentityDone(() => {
  notifier?.success(
    t("Identity {displayName} updated", {
      displayName: displayName(identity.value),
    }) as string
  );
});

updateIdentityError((err) => handleError(err));

const updateIdentity = async (): Promise<void> => {
  const variables = await buildVariables();

  updateIdentityMutation(variables);
};

const {
  mutate: createIdentityMutation,
  onDone: createIdentityDone,
  onError: createIdentityError,
} = useMutation(CREATE_PERSON, () => ({
  update: (
    store: ApolloCache<InMemoryCache>,
    { data: updateData }: FetchResult
  ) => {
    const data = store.readQuery<{ loggedUser: Pick<ICurrentUser, "actors"> }>({
      query: IDENTITIES,
    });

    if (data && updateData?.createPerson) {
      store.writeQuery({
        query: IDENTITIES,
        data: {
          loggedUser: {
            ...data.loggedUser,
            actors: [
              ...data.loggedUser.actors,
              { ...updateData?.createPerson, type: ActorType.PERSON },
            ],
          },
        },
      });
    }
  },
}));

createIdentityDone(() => {
  notifier?.success(
    t("Identity {displayName} created", {
      displayName: displayName(identity.value),
    })
  );

  router.push({
    name: RouteName.UPDATE_IDENTITY,
    params: { identityName: identity.value.preferredUsername },
  });
});

createIdentityError((err) => handleError(err));

const createIdentity = async (): Promise<void> => {
  const variables = await buildVariables();

  createIdentityMutation(variables);
};

const handleErrors = (absintheErrors: AbsintheGraphQLErrors): void => {
  if (absintheErrors.some((error) => error.status_code === 401)) {
    router.push({ name: RouteName.LOGIN });
  }
};

// eslint-disable-next-line class-methods-use-this
const getInstanceHost = computed((): string => {
  return MOBILIZON_INSTANCE_HOST;
});

const tokenToURL = (token: string, format: string): string => {
  return `${window.location.origin}/events/going/${token}/${format}`;
};

const copyURL = (e: Event, url: string, format: "ics" | "atom"): void => {
  if (navigator.clipboard) {
    e.preventDefault();
    navigator.clipboard.writeText(url);
    showCopiedTooltip[format] = true;
    setTimeout(() => {
      showCopiedTooltip[format] = false;
    }, 2000);
  }
};

const generateFeedTokens = async (): Promise<void> => {
  await createNewFeedToken({ actorId: identity.value?.id });
};

const regenerateFeedTokens = async (): Promise<void> => {
  if (identity.value?.feedTokens.length < 1) return;
  await deleteFeedToken({ token: identity.value.feedTokens[0].token });
  await createNewFeedToken(
    { actorId: identity.value?.id },
    {
      update(cache, { data }) {
        const actorId = data?.createFeedToken.actor?.id;
        const newFeedToken = data?.createFeedToken.token;

        if (!newFeedToken) return;

        let cachedData = cache.readFragment<{
          id: string | undefined;
          feedTokens: { token: string }[];
        }>({
          id: `Person:${actorId}`,
          fragment: PERSON_FRAGMENT_FEED_TOKENS,
        });
        // Remove the old token
        cachedData = {
          id: cachedData?.id,
          feedTokens: [
            ...(cachedData?.feedTokens ?? []).slice(0, -1),
            { token: newFeedToken },
          ],
        };
        cache.writeFragment({
          id: `Person:${actorId}`,
          fragment: PERSON_FRAGMENT_FEED_TOKENS,
          data: cachedData,
        });
      },
    }
  );
};

const { mutate: deleteFeedToken } = useMutation(DELETE_FEED_TOKEN);

const { mutate: createNewFeedToken } = useMutation<{
  createFeedToken: IFeedToken;
}>(CREATE_FEED_TOKEN_ACTOR, () => ({
  update(cache, { data }) {
    const actorId = data?.createFeedToken.actor?.id;
    const newFeedToken = data?.createFeedToken.token;

    if (!newFeedToken) return;

    let cachedData = cache.readFragment<{
      id: string | undefined;
      feedTokens: { token: string }[];
    }>({
      id: `Person:${actorId}`,
      fragment: PERSON_FRAGMENT_FEED_TOKENS,
    });
    // Add the new token to the list
    cachedData = {
      id: cachedData?.id,
      feedTokens: [...(cachedData?.feedTokens ?? []), { token: newFeedToken }],
    };
    cache.writeFragment({
      id: `Person:${actorId}`,
      fragment: PERSON_FRAGMENT_FEED_TOKENS,
      data: cachedData,
    });
  },
}));

const dialog = inject<Dialog>("dialog");

const openRegenerateFeedTokensConfirmation = (): void => {
  dialog?.confirm({
    variant: "warning",
    title: t("Regenerate new links") as string,
    message: t(
      "You'll need to change the URLs where there were previously entered."
    ) as string,
    confirmText: t("Regenerate new links") as string,
    cancelText: t("Cancel") as string,
    onConfirm: () => regenerateFeedTokens(),
  });
};

const openDeleteIdentityConfirmation = (): void => {
  dialog?.prompt({
    variant: "danger",
    title: t("Delete your identity") as string,
    message: `${t(
      "This will delete / anonymize all content (events, comments, messages, participations…) created from this identity."
    )}
            <br /><br />
            ${t(
              "If this identity is the only administrator of some groups, you need to delete them before being able to delete this identity."
            )}
            ${t(
              "Otherwise this identity will just be removed from the group administrators."
            )}
            <br /><br />
            ${t(
              'To confirm, type your identity username "{preferredUsername}"',
              {
                preferredUsername: identity.value.preferredUsername,
              }
            )}`,
    confirmText: t("Delete {preferredUsername}", {
      preferredUsername: identity.value.preferredUsername,
    }),
    inputAttrs: {
      placeholder: identity.value.preferredUsername,
      pattern: identity.value.preferredUsername,
    },
    onConfirm: () => deleteIdentity(),
  });
};

const handleError = (err: any) => {
  console.error(err);

  if (err?.networkError?.name === "ServerParseError") {
    const error = err?.networkError as ServerParseError;

    if (error?.response?.status === 413) {
      const errorMessage = props.isUpdate
        ? t(
            "Unable to update the profile. The avatar picture may be too heavy."
          )
        : t(
            "Unable to create the profile. The avatar picture may be too heavy."
          );
      errors.value.push(errorMessage as string);
    }
  }

  if (err.graphQLErrors !== undefined) {
    err.graphQLErrors.forEach(
      ({ message: errorMessage }: { message: string }) => {
        notifier?.error(errorMessage);
      }
    );
  }
};

const buildVariables = async (): Promise<Record<string, unknown>> => {
  /**
   * We set the avatar only if user has selected one
   */
  let avatarObj: Record<string, unknown> = { avatar: null };
  if (avatarFile.value) {
    avatarObj = buildFileVariable(
      avatarFile.value,
      "avatar",
      `${identity.value.preferredUsername}'s avatar`
    );
  }
  return pick({ ...identity.value, ...avatarObj }, [
    "id",
    "preferredUsername",
    "name",
    "summary",
    "avatar",
  ]);
};

const redirectIfNoIdentitySelected = async (identityParam?: string) => {
  if (identityParam) return;

  // await loadLoggedPersonIfNeeded();

  if (currentActor.value) {
    await router.push({
      params: { identityName: currentActor.value?.preferredUsername },
    });
  }
};

const maybeUpdateCurrentActorCache = async (newIdentity: IPerson) => {
  if (currentActor.value) {
    if (
      currentActor.value.preferredUsername === identity.value.preferredUsername
    ) {
      await changeIdentity(newIdentity);
    }
    // currentActor.value = newIdentity;
  }
};

// const loadLoggedPersonIfNeeded = async (bypassCache = false) => {
//   if (currentActor.value) return;

//   const result = await this.$apollo.query({
//     query: CURRENT_ACTOR_CLIENT,
//     fetchPolicy: bypassCache ? "network-only" : undefined,
//   });

//   currentActor.value = result.data.currentActor;
// };

const resetFields = () => {
  // identity.value = new Person();
  // oldDisplayName.value = null;
  avatarFile.value = null;
};

const breadcrumbsLinks = computed(
  (): { name: string; params: Record<string, any>; text: string }[] => {
    const links = [
      {
        name: RouteName.IDENTITIES,
        params: {},
        text: t("Profiles") as string,
      },
    ];
    if (props.isUpdate && identity.value) {
      links.push({
        name: RouteName.UPDATE_IDENTITY,
        params: { identityName: identity.value.preferredUsername },
        text: identity.value.name,
      });
    } else {
      links.push({
        name: RouteName.CREATE_IDENTITY,
        params: {},
        text: t("New profile") as string,
      });
    }
    return links;
  }
);

const updateUsername = (value: string) => {
  identity.value.preferredUsername = convertToUsername(value);
};
</script>
