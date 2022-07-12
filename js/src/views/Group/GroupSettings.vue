<template>
  <div>
    <breadcrumbs-nav
      v-if="group"
      :links="[
        {
          name: RouteName.GROUP,
          params: { preferredUsername: usernameWithDomain(group) },
          text: displayName(group),
        },
        {
          name: RouteName.GROUP_SETTINGS,
          params: { preferredUsername: usernameWithDomain(group) },
          text: $t('Settings'),
        },
        {
          name: RouteName.GROUP_PUBLIC_SETTINGS,
          params: { preferredUsername: usernameWithDomain(group) },
          text: $t('Group settings'),
        },
      ]"
    />
    <o-loading :active="loading" />
    <section
      class="container mx-auto section"
      v-if="group && isCurrentActorAGroupAdmin"
    >
      <form @submit.prevent="updateGroup">
        <o-field :label="$t('Group name')" label-for="group-settings-name">
          <o-input v-model="editableGroup.name" id="group-settings-name" />
        </o-field>
        <o-field :label="$t('Group short description')">
          <Editor
            mode="basic"
            v-model="editableGroup.summary"
            :maxSize="500"
            :aria-label="$t('Group description body')"
            v-if="currentActor"
            :currentActor="currentActor"
        /></o-field>
        <o-field :label="$t('Avatar')">
          <picture-upload
            :textFallback="$t('Avatar')"
            v-model="avatarFile"
            :defaultImage="group.avatar"
            :maxSize="avatarMaxSize"
          />
        </o-field>

        <o-field :label="$t('Banner')">
          <picture-upload
            :textFallback="$t('Banner')"
            v-model="bannerFile"
            :defaultImage="group.banner"
            :maxSize="bannerMaxSize"
          />
        </o-field>
        <p class="label">{{ $t("Group visibility") }}</p>
        <div class="field">
          <o-radio
            v-model="editableGroup.visibility"
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
        </div>
        <div class="field">
          <o-radio
            v-model="editableGroup.visibility"
            name="groupVisibility"
            :native-value="GroupVisibility.UNLISTED"
            >{{ $t("Only accessible through link") }}<br />
            <small>{{
              $t(
                "You'll need to transmit the group URL so people may access the group's profile. The group won't be findable in Mobilizon's search or regular search engines."
              )
            }}</small>
          </o-radio>
          <p class="pl-6">
            <code>{{ group.url }}</code>
            <o-tooltip
              v-if="canShowCopyButton"
              :label="$t('URL copied to clipboard')"
              :active="showCopiedTooltip"
              always
              variant="success"
              position="left"
            >
              <o-button
                variant="primary"
                icon-right="content-paste"
                native-type="button"
                @click="copyURL"
                @keyup.enter="copyURL"
              />
            </o-tooltip>
          </p>
        </div>

        <p class="label">{{ $t("New members") }}</p>
        <div class="field">
          <o-radio
            v-model="editableGroup.openness"
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
        </div>
        <div class="field">
          <o-radio
            v-model="editableGroup.openness"
            name="groupOpenness"
            :native-value="Openness.MODERATED"
            >{{ $t("Moderate new members") }}<br />
            <small>{{
              $t(
                "Anyone can request being a member, but an administrator needs to approve the membership."
              )
            }}</small>
          </o-radio>
        </div>
        <div class="field">
          <o-radio
            v-model="editableGroup.openness"
            name="groupOpenness"
            :native-value="Openness.INVITE_ONLY"
            >{{ $t("Manually invite new members") }}<br />
            <small>{{
              $t(
                "The only way for your group to get new members is if an admininistrator invites them."
              )
            }}</small>
          </o-radio>
        </div>

        <o-field
          :label="$t('Followers')"
          :message="$t('Followers will receive new public events and posts.')"
        >
          <o-checkbox v-model="editableGroup.manuallyApprovesFollowers">
            {{ $t("Manually approve new followers") }}
          </o-checkbox>
        </o-field>

        <full-address-auto-complete
          :label="$t('Group address')"
          v-model="currentAddress"
          :hideMap="true"
        />

        <div class="flex flex-wrap gap-2 my-2">
          <o-button native-type="submit" variant="primary">{{
            $t("Update group")
          }}</o-button>
          <o-button @click="confirmDeleteGroup" variant="danger">{{
            $t("Delete group")
          }}</o-button>
        </div>
      </form>
      <o-notification
        variant="danger"
        v-for="(value, index) in errors"
        :key="index"
      >
        {{ value }}
      </o-notification>
    </section>
    <o-notification v-else-if="!loading">
      {{ $t("You are not an administrator for this group.") }}
    </o-notification>
  </div>
</template>

<script lang="ts" setup>
import FullAddressAutoComplete from "@/components/Event/FullAddressAutoComplete.vue";
import PictureUpload from "@/components/PictureUpload.vue";
import { GroupVisibility, MemberRole, Openness } from "@/types/enums";
import { Group, IGroup, usernameWithDomain, displayName } from "@/types/actor";
import { Address, IAddress } from "@/types/address.model";
import { ServerParseError } from "@apollo/client/link/http";
import { ErrorResponse } from "@apollo/client/link/error";
import RouteName from "@/router/name";
import { buildFileFromIMedia } from "@/utils/image";
import { useAvatarMaxSize, useBannerMaxSize } from "@/composition/config";
import { useI18n } from "vue-i18n";
import { computed, ref, watch, defineAsyncComponent, inject } from "vue";
import { useGroup, useUpdateGroup } from "@/composition/apollo/group";
import {
  useCurrentActorClient,
  usePersonStatusGroup,
} from "@/composition/apollo/actor";
import { DELETE_GROUP } from "@/graphql/group";
import { useMutation } from "@vue/apollo-composable";
import { useRouter } from "vue-router";
import { Dialog } from "@/plugins/dialog";
import { useHead } from "@vueuse/head";
import { Notifier } from "@/plugins/notifier";

const Editor = defineAsyncComponent(() => import("@/components/Editor.vue"));

const props = defineProps<{ preferredUsername: string }>();

const { currentActor } = useCurrentActorClient();

const { group, loading } = useGroup(props.preferredUsername);

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => t("Group settings")),
});

const notifier = inject<Notifier>("notifier");

const avatarFile = ref<File | null>(null);
const bannerFile = ref<File | null>(null);

const errors = ref<string[]>([]);

const showCopiedTooltip = ref(false);

const editableGroup = ref<IGroup>(new Group());

const updateGroup = async (): Promise<void> => {
  const variables = buildVariables();
  const { onDone, onError } = useUpdateGroup(variables);

  onDone(() => {
    notifier?.success(t("Group settings saved") as string);
  });

  onError((err) => {
    handleError(err as unknown as ErrorResponse);
  });
};

const copyURL = async (): Promise<void> => {
  await window.navigator.clipboard.writeText(group.value?.url ?? "");
  showCopiedTooltip.value = true;
  setTimeout(() => {
    showCopiedTooltip.value = false;
  }, 2000);
};

watch(group, async (oldGroup: IGroup, newGroup: IGroup) => {
  try {
    if (
      oldGroup?.avatar !== undefined &&
      oldGroup?.avatar !== newGroup?.avatar
    ) {
      avatarFile.value = await buildFileFromIMedia(group.value?.avatar);
    }
    if (
      oldGroup?.banner !== undefined &&
      oldGroup?.banner !== newGroup?.banner
    ) {
      bannerFile.value = await buildFileFromIMedia(group.value?.banner);
    }
  } catch (e) {
    // Catch errors while building media
    console.error(e);
  }
  editableGroup.value = { ...group.value };
});

const buildVariables = () => {
  let avatarObj = {};
  let bannerObj = {};
  const variables = { ...editableGroup.value };
  let physicalAddress;
  if (variables.physicalAddress) {
    physicalAddress = { ...variables.physicalAddress };
  } else {
    physicalAddress = variables.physicalAddress;
  }

  // eslint-disable-next-line
  // @ts-ignore
  if (variables.__typename) {
    // eslint-disable-next-line
    // @ts-ignore
    delete variables.__typename;
  }
  // eslint-disable-next-line
  // @ts-ignore
  if (physicalAddress && physicalAddress.__typename) {
    // eslint-disable-next-line
    // @ts-ignore
    delete physicalAddress.__typename;
  }
  delete variables.avatar;
  delete variables.banner;

  if (avatarFile.value) {
    avatarObj = {
      avatar: {
        media: {
          name: avatarFile.value?.name,
          alt: `${editableGroup.value?.preferredUsername}'s avatar`,
          file: avatarFile,
        },
      },
    };
  }

  if (bannerFile.value) {
    bannerObj = {
      banner: {
        media: {
          name: bannerFile.value?.name,
          alt: `${editableGroup.value?.preferredUsername}'s banner`,
          file: bannerFile,
        },
      },
    };
  }
  return {
    id: group.value?.id,
    name: editableGroup.value?.name,
    summary: editableGroup.value?.summary,
    visibility: editableGroup.value?.visibility,
    openness: editableGroup.value?.openness,
    manuallyApprovesFollowers: editableGroup.value?.manuallyApprovesFollowers,
    physicalAddress,
    ...avatarObj,
    ...bannerObj,
  };
};

const canShowCopyButton = computed((): boolean => {
  return window.isSecureContext;
});

const currentAddress = computed({
  get(): IAddress {
    return new Address(editableGroup.value?.physicalAddress);
  },
  set(address: IAddress) {
    editableGroup.value.physicalAddress = address;
  },
});

const avatarMaxSize = useAvatarMaxSize();
const bannerMaxSize = useBannerMaxSize();

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
  errors.value.push(
    ...(err.graphQLErrors || []).map(
      ({ message }: { message: string }) => message
    )
  );
};

const isCurrentActorAGroupAdmin = computed((): boolean => {
  return hasCurrentActorThisRole(MemberRole.ADMINISTRATOR);
});

const hasCurrentActorThisRole = (givenRole: string | string[]): boolean => {
  const roles = Array.isArray(givenRole) ? givenRole : [givenRole];
  return (
    personMemberships.value?.total > 0 &&
    roles.includes(personMemberships.value?.elements[0].role)
  );
};

const personMemberships = computed(
  () => person.value?.memberships ?? { total: 0, elements: [] }
);

const { person } = usePersonStatusGroup(props.preferredUsername);

const dialog = inject<Dialog>("dialog");

const confirmDeleteGroup = (): void => {
  console.debug("confirm delete group", dialog);
  dialog?.confirm({
    title: t("Delete group"),
    message: t(
      "Are you sure you want to <b>completely delete</b> this group? All members - including remote ones - will be notified and removed from the group, and <b>all of the group data (events, posts, discussions, todos…) will be irretrievably destroyed</b>."
    ),
    confirmText: t("Delete group"),
    cancelText: t("Cancel"),
    type: "danger",
    hasIcon: true,
    onConfirm: () =>
      deleteGroupMutation({
        groupId: group.value?.id,
      }),
  });
};

const { mutate: deleteGroupMutation, onDone: deleteGroupDone } = useMutation<{
  deleteGroup: IGroup;
}>(DELETE_GROUP);

const router = useRouter();

deleteGroupDone(() => {
  router.push({ name: RouteName.MY_GROUPS });
});
</script>
