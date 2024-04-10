<template>
  <section class="container mx-auto">
    <h1>{{ t("Create a new group") }}</h1>

    <o-notification
      variant="danger"
      v-for="(value, index) in errors"
      :key="index"
    >
      {{ value }}
    </o-notification>

    <form @submit.prevent="createGroup">
      <o-field :label="t('Group display name')" label-for="group-display-name">
        <o-input
          aria-required="true"
          required
          expanded
          v-model="group.name"
          id="group-display-name"
        />
      </o-field>

      <div class="field">
        <label class="label" for="group-preferred-username">{{
          t("Federated Group Name")
        }}</label>
        <div class="field-body">
          <o-field
            :message="preferredUsernameErrors[0]"
            :type="preferredUsernameErrors[1]"
          >
            <o-input
              ref="preferredUsernameInput"
              aria-required="true"
              required
              expanded
              v-model="group.preferredUsername"
              pattern="[a-z0-9_]+"
              id="group-preferred-username"
              :useHtml5Validation="true"
              :validation-message="
                group.preferredUsername
                  ? t(
                      'Only alphanumeric lowercased characters and underscores are supported.'
                    )
                  : null
              "
            />
            <p class="control">
              <span class="button is-static">@{{ host }}</span>
            </p>
          </o-field>
        </div>
        <i18n-t
          v-if="currentActor"
          keypath="This is like your federated username ({username}) for groups. It will allow the group to be found on the federation, and is guaranteed to be unique."
        >
          <template #username>
            <code>
              {{ usernameWithDomain(currentActor, true) }}
            </code>
          </template>
        </i18n-t>
      </div>

      <o-field
        :label="t('Description')"
        label-for="group-summary"
        :message="summaryErrors[0]"
        :type="summaryErrors[1]"
      >
        <editor
          v-if="currentActor"
          id="group-summary"
          mode="basic"
          class="mb-3"
          v-model="group.summary"
          :maxSize="500"
          :aria-label="$t('Group description body')"
          :current-actor="currentActor"
        />
      </o-field>

      <full-address-auto-complete
        :label="$t('Group address')"
        v-model="group.physicalAddress"
      />

      <div class="field">
        <b class="field-label">{{ t("Avatar") }}</b>
        <picture-upload
          :textFallback="t('Avatar')"
          v-model="avatarFile"
          :maxSize="avatarMaxSize"
        />
      </div>

      <div class="field">
        <b class="field-label">{{ t("Banner") }}</b>
        <picture-upload
          :textFallback="t('Banner')"
          v-model="bannerFile"
          :maxSize="bannerMaxSize"
        />
      </div>

      <fieldset>
        <legend class="field-label !mb-0 mt-2">
          {{ t("Group visibility") }}
        </legend>
        <o-radio
          v-model="group.visibility"
          name="groupVisibility"
          :native-value="GroupVisibility.PUBLIC"
        >
          {{ $t("Visible everywhere on the web") }}<br />
          <small>{{
            $t(
              "The group will be publicly listed in search results and may be suggested in the explore section. Only public informations will be shown on it's page."
            )
          }}</small>
        </o-radio>
        <o-radio
          v-model="group.visibility"
          name="groupVisibility"
          :native-value="GroupVisibility.UNLISTED"
          >{{ $t("Only accessible through link") }}<br />
          <small>{{
            $t(
              "You'll need to transmit the group URL so people may access the group's profile. The group won't be findable in Mobilizon's search or regular search engines."
            )
          }}</small>
        </o-radio>
      </fieldset>
      <fieldset>
        <legend class="mt-2">
          <span class="field-label !mb-0">{{ t("New members") }} </span>
          <span>
            {{
              t(
                "Members will also access private sections like discussions, resources and restricted posts."
              )
            }}
          </span>
        </legend>
        <o-field>
          <o-radio
            v-model="group.openness"
            name="groupOpenness"
            :native-value="Openness.OPEN"
          >
            {{ $t("Anyone can join freely") }}<br />
            <small>{{
              $t(
                "Anyone wanting to be a member from your group will be able to from your group page."
              )
            }}</small>
          </o-radio>
        </o-field>
        <o-field>
          <o-radio
            v-model="group.openness"
            name="groupOpenness"
            :native-value="Openness.MODERATED"
            >{{ $t("Moderate new members") }}<br />
            <small>{{
              $t(
                "Anyone can request being a member, but an administrator needs to approve the membership."
              )
            }}</small>
          </o-radio>
        </o-field>
        <o-field>
          <o-radio
            v-model="group.openness"
            name="groupOpenness"
            :native-value="Openness.INVITE_ONLY"
            >{{ $t("Manually invite new members") }}<br />
            <small>{{
              $t(
                "The only way for your group to get new members is if an admininistrator invites them."
              )
            }}</small>
          </o-radio>
        </o-field>
      </fieldset>
      <fieldset>
        <legend class="mt-2">
          <span class="field-label !mb-0">
            {{ t("Followers") }}
          </span>
          <span>
            {{ t("Followers will receive new public events and posts.") }}
          </span>
        </legend>
        <o-checkbox v-model="group.manuallyApprovesFollowers">
          {{ t("Manually approve new followers") }}
        </o-checkbox>
      </fieldset>

      <o-button variant="primary" native-type="submit" class="mt-3">
        {{ t("Create my group") }}
      </o-button>
    </form>
  </section>
</template>

<script lang="ts" setup>
import { Group, usernameWithDomain, displayName } from "@/types/actor";
import RouteName from "../../router/name";
import { convertToUsername } from "../../utils/username";
import PictureUpload from "../../components/PictureUpload.vue";
import { ErrorResponse } from "@/types/errors.model";
import { ServerParseError } from "@apollo/client/link/http";
import { useCurrentActorClient } from "@/composition/apollo/actor";
import {
  computed,
  defineAsyncComponent,
  inject,
  reactive,
  ref,
  watch,
} from "vue";
import { useRouter } from "vue-router";
import { useI18n } from "vue-i18n";
import { useCreateGroup } from "@/composition/apollo/group";
import {
  useAvatarMaxSize,
  useBannerMaxSize,
  useHost,
} from "@/composition/config";
import { Notifier } from "@/plugins/notifier";
import { useHead } from "@/utils/head";
import { Openness, GroupVisibility } from "@/types/enums";
import FullAddressAutoComplete from "@/components/Event/FullAddressAutoComplete.vue";

const Editor = defineAsyncComponent(
  () => import("@/components/TextEditor.vue")
);

const { currentActor } = useCurrentActorClient();

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => t("Create a new group")),
});

const group = ref(new Group());

const avatarFile = ref<File | null>(null);
const bannerFile = ref<File | null>(null);

const errors = ref<string[]>([]);

const fieldErrors = reactive<Record<string, string | undefined>>({
  preferred_username: undefined,
  summary: undefined,
});

const router = useRouter();

const host = useHost();
const avatarMaxSize = useAvatarMaxSize();
const bannerMaxSize = useBannerMaxSize();

const notifier = inject<Notifier>("notifier");

watch(
  () => group.value.name,
  (newGroupName) => {
    group.value.preferredUsername = convertToUsername(newGroupName);
  }
);

const buildVariables = computed(() => {
  let avatarObj = {};
  let bannerObj = {};

  const cloneGroup = group.value;
  // eslint-disable-next-line @typescript-eslint/ban-ts-comment
  // @ts-ignore
  delete cloneGroup.physicalAddress.__typename;
  delete cloneGroup.physicalAddress.pictureInfo;

  const groupBasic = {
    preferredUsername: group.value.preferredUsername,
    name: group.value.name,
    summary: group.value.summary,
    visibility: group.value.visibility,
    openness: group.value.openness,
    manuallyApprovesFollowers: group.value.manuallyApprovesFollowers,
  };

  if (cloneGroup.physicalAddress?.id || cloneGroup.physicalAddress?.geom) {
    // @ts-expect-error No type for this variable
    groupBasic.physicalAddress = cloneGroup.physicalAddress;
  }

  if (avatarFile.value) {
    avatarObj = {
      avatar: {
        media: {
          name: avatarFile.value?.name,
          alt: `${group.value.preferredUsername}'s avatar`,
          file: avatarFile.value,
        },
      },
    };
  }

  if (bannerFile.value) {
    bannerObj = {
      banner: {
        media: {
          name: bannerFile.value?.name,
          alt: `${group.value.preferredUsername}'s banner`,
          file: bannerFile.value,
        },
      },
    };
  }

  return {
    ...groupBasic,
    ...avatarObj,
    ...bannerObj,
  };
});

const handleError = (err: ErrorResponse) => {
  if (err?.networkError?.name === "ServerParseError") {
    const error = err?.networkError as ServerParseError;

    if (error?.response?.status === 413) {
      errors.value.push(
        t(
          "Unable to create the group. One of the pictures may be too heavy."
        ) as string
      );
    }
  }
  err.graphQLErrors?.forEach((error) => {
    if (error.field) {
      if (Array.isArray(error.message)) {
        fieldErrors[error.field] = error.message[0];
      } else {
        fieldErrors[error.field] = error.message;
      }
    } else {
      errors.value.push(error.message);
    }
  });
};

const summaryErrors = computed(() => {
  const message = fieldErrors.summary ? fieldErrors.summary : undefined;
  const type = fieldErrors.summary ? "danger" : undefined;
  return [message, type];
});

const preferredUsernameErrors = computed(() => {
  const message = fieldErrors.preferred_username
    ? fieldErrors.preferred_username
    : t(
        "Only alphanumeric lowercased characters and underscores are supported."
      );
  const type = fieldErrors.preferred_username ? "danger" : undefined;
  return [message, type];
});

const { onDone, onError, mutate } = useCreateGroup();

onDone(() => {
  notifier?.success(
    t("Group {displayName} created", {
      displayName: displayName(group.value),
    })
  );

  router.push({
    name: RouteName.GROUP,
    params: { preferredUsername: usernameWithDomain(group.value) },
  });
});

onError((err) => handleError(err as unknown as ErrorResponse));

const createGroup = async (): Promise<void> => {
  errors.value = [];
  fieldErrors.preferred_username = undefined;
  fieldErrors.summary = undefined;
  mutate(buildVariables.value);
};
</script>

<style>
.markdown-render h1 {
  font-size: 2em;
}
</style>
