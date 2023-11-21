<template>
  <div v-if="user">
    <breadcrumbs-nav
      :links="[
        { name: RouteName.ADMIN, text: t('Admin') },
        {
          name: RouteName.USERS,
          text: t('Users'),
        },
        {
          name: RouteName.ADMIN_USER_PROFILE,
          params: { id: user.id },
          text: user.email,
        },
      ]"
    />

    <section>
      <h2 class="text-lg font-bold mb-3">{{ t("Details") }}</h2>
      <div class="flex flex-col">
        <div class="overflow-x-auto">
          <div class="inline-block py-2 min-w-full sm:px-2">
            <div class="overflow-hidden shadow-md sm:rounded-lg">
              <table v-if="metadata.length > 0" class="table w-full">
                <tbody>
                  <tr
                    class="border-b"
                    v-for="{ key, value, type } in metadata"
                    :key="key"
                  >
                    <td class="py-4 px-2 whitespace-nowrap align-middle">
                      {{ key }}
                    </td>

                    <td
                      v-if="type === 'ip'"
                      class="py-4 px-2 whitespace-nowrap"
                    >
                      <code class="truncate block max-w-[15rem]">{{
                        value
                      }}</code>
                    </td>
                    <td
                      v-else-if="type === 'role'"
                      class="py-4 px-2 whitespace-nowrap"
                    >
                      <span
                        :class="{
                          'bg-red-100 text-red-800':
                            user.role == ICurrentUserRole.ADMINISTRATOR,
                          'bg-yellow-100 text-yellow-800':
                            user.role == ICurrentUserRole.MODERATOR,
                          'bg-blue-100 text-blue-800':
                            user.role == ICurrentUserRole.USER,
                        }"
                        class="text-sm font-medium mr-2 px-2.5 py-0.5 rounded"
                      >
                        {{ value }}
                      </span>
                    </td>
                    <td v-else class="py-4 px-2 align-middle">
                      {{ value }}
                    </td>
                    <td
                      v-if="type === 'email'"
                      class="py-4 px-2 whitespace-nowrap flex flex flex-col items-start gap-2"
                    >
                      <o-button
                        size="small"
                        v-if="!user.disabled"
                        @click="isEmailChangeModalActive = true"
                        variant="text"
                        icon-left="pencil"
                        >{{ t("Change email") }}</o-button
                      >
                      <o-button
                        tag="router-link"
                        :to="{
                          name: RouteName.USERS,
                          query: { emailFilter: `@${userEmailDomain}` },
                        }"
                        size="small"
                        variant="text"
                        icon-left="magnify"
                        >{{
                          t("Other users with the same email domain")
                        }}</o-button
                      >
                    </td>
                    <td
                      v-else-if="type === 'confirmed'"
                      class="py-4 px-2 whitespace-nowrap flex items-center"
                    >
                      <o-button
                        size="small"
                        v-if="!user.confirmedAt || user.disabled"
                        @click="isConfirmationModalActive = true"
                        variant="text"
                        icon-left="check"
                        >{{ t("Confirm user") }}</o-button
                      >
                    </td>
                    <td
                      v-else-if="type === 'role'"
                      class="py-4 px-2 whitespace-nowrap flex items-center"
                    >
                      <o-button
                        size="small"
                        v-if="!user.disabled"
                        @click="isRoleChangeModalActive = true"
                        variant="text"
                        icon-left="chevron-double-up"
                        >{{ t("Change role") }}</o-button
                      >
                    </td>
                    <td
                      v-else-if="type === 'ip' && user.currentSignInIp"
                      class="py-4 px-2 whitespace-nowrap flex items-center"
                    >
                      <o-button
                        tag="router-link"
                        :to="{
                          name: RouteName.USERS,
                          query: { ipFilter: user.currentSignInIp },
                        }"
                        size="small"
                        variant="text"
                        icon-left="web"
                        >{{
                          t("Other users with the same IP address")
                        }}</o-button
                      >
                    </td>
                    <td v-else></td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </section>
    <section class="my-4">
      <h2 class="text-lg font-bold mb-3">{{ t("Profiles") }}</h2>
      <div
        class="flex flex-wrap justify-center sm:justify-start gap-4"
        v-if="profiles && profiles.length > 0"
      >
        <router-link
          v-for="profile in profiles"
          :key="profile.id"
          :to="{ name: RouteName.ADMIN_PROFILE, params: { id: profile.id } }"
        >
          <actor-card
            :actor="profile"
            :full="true"
            :popover="false"
            :limit="true"
          />
        </router-link>
      </div>
      <empty-content v-else-if="!loadingUser" :inline="true" icon="account">
        {{ t("This user doesn't have any profiles") }}
      </empty-content>
    </section>
    <section class="my-4">
      <h2 class="text-lg font-bold mb-3">{{ t("Actions") }}</h2>
      <div class="buttons" v-if="!user.disabled">
        <o-button @click="suspendAccount" variant="danger">{{
          t("Suspend")
        }}</o-button>
      </div>
      <div
        v-else
        class="p-4 mb-4 text-sm text-red-700 bg-red-100 rounded-lg"
        role="alert"
      >
        {{ t("The user has been disabled") }}
      </div>
    </section>
    <o-modal
      v-model:active="isEmailChangeModalActive"
      trap-focus
      :destroy-on-hide="false"
      aria-role="dialog"
      :aria-label="t('Edit user email')"
      :close-button-aria-label="t('Close')"
      aria-modal
    >
      <form @submit.prevent="updateUserEmail">
        <div class="" style="width: auto">
          <header class="">
            <h2>{{ t("Change user email") }}</h2>
          </header>
          <section class="">
            <o-field :label="t('Previous email')">
              <o-input type="email" v-model="user.email" disabled />
            </o-field>
            <o-field :label="t('New email')">
              <o-input
                type="email"
                v-model="newUser.email"
                :placeholder="t(`new{'@'}email.com`)"
                required
              >
              </o-input>
            </o-field>
            <o-checkbox v-model="newUser.notify">{{
              t("Notify the user of the change")
            }}</o-checkbox>
          </section>
          <footer class="mt-2 flex gap-2">
            <o-button outlined @click="isEmailChangeModalActive = false">{{
              t("Close")
            }}</o-button>
            <o-button native-type="submit" variant="primary">{{
              t("Change email")
            }}</o-button>
          </footer>
        </div>
      </form>
    </o-modal>
    <o-modal
      v-model:active="isRoleChangeModalActive"
      has-modal-card
      trap-focus
      :destroy-on-hide="false"
      aria-role="dialog"
      :aria-label="t('Edit user email')"
      :close-button-aria-label="t('Close')"
      aria-modal
    >
      <form @submit.prevent="updateUserRole">
        <header>
          <h2>{{ t("Change user role") }}</h2>
        </header>
        <section>
          <o-field>
            <o-radio
              v-model="newUser.role"
              :native-value="ICurrentUserRole.ADMINISTRATOR"
            >
              {{ t("Administrator") }}
            </o-radio>
          </o-field>
          <o-field>
            <o-radio
              v-model="newUser.role"
              :native-value="ICurrentUserRole.MODERATOR"
            >
              {{ t("Moderator") }}
            </o-radio>
          </o-field>
          <o-field>
            <o-radio
              v-model="newUser.role"
              :native-value="ICurrentUserRole.USER"
            >
              {{ t("User") }}
            </o-radio>
          </o-field>
          <o-checkbox v-model="newUser.notify">{{
            t("Notify the user of the change")
          }}</o-checkbox>
        </section>
        <footer class="mt-2 flex gap-2">
          <o-button @click="isRoleChangeModalActive = false" outlined>{{
            t("Close")
          }}</o-button>
          <o-button native-type="submit" variant="primary">{{
            t("Change role")
          }}</o-button>
        </footer>
      </form>
    </o-modal>
    <o-modal
      v-model:active="isConfirmationModalActive"
      has-modal-card
      trap-focus
      :destroy-on-hide="false"
      aria-role="dialog"
      :aria-label="t('Edit user email')"
      :close-button-aria-label="t('Close')"
      aria-modal
    >
      <form @submit.prevent="confirmUser">
        <header>
          <h2>{{ t("Confirm user") }}</h2>
        </header>
        <section>
          <o-checkbox v-model="newUser.notify">{{
            t("Notify the user of the change")
          }}</o-checkbox>
        </section>
        <footer>
          <o-button @click="isConfirmationModalActive = false">{{
            t("Close")
          }}</o-button>
          <o-button native-type="submit" variant="primary">{{
            t("Confirm user")
          }}</o-button>
        </footer>
      </form>
    </o-modal>
  </div>
  <empty-content v-else-if="!loadingUser" icon="account">
    {{ t("This user was not found") }}
    <template #desc>
      <o-button
        variant="text"
        tag="router-link"
        :to="{ name: RouteName.USERS }"
        >{{ t("Back to user list") }}</o-button
      >
    </template>
  </empty-content>
</template>
<script lang="ts" setup>
import { formatBytes } from "@/utils/datetime";
import { ICurrentUserRole } from "@/types/enums";
import { GET_USER, SUSPEND_USER } from "../../graphql/user";
import RouteName from "../../router/name";
import { IUser } from "../../types/current-user.model";
import EmptyContent from "../../components/Utils/EmptyContent.vue";
import ActorCard from "../../components/Account/ActorCard.vue";
import { ADMIN_UPDATE_USER, LANGUAGES_CODES } from "@/graphql/admin";
import { useMutation, useQuery } from "@vue/apollo-composable";
import { ILanguage } from "@/types/admin.model";
import { computed, inject, reactive, ref, watch } from "vue";
import { useHead } from "@unhead/vue";
import { useI18n } from "vue-i18n";
import { formatDateTimeString } from "@/filters/datetime";
import { useRouter } from "vue-router";
import { IPerson } from "@/types/actor";
import { Dialog } from "@/plugins/dialog";

const props = defineProps<{ id: string }>();

const { result: userResult, loading: loadingUser } = useQuery<{ user: IUser }>(
  GET_USER,
  () => ({
    id: props.id,
  })
);

const user = computed(() => userResult.value?.user);

const languageCode = computed(() => user.value?.locale);

const { result: languagesResult } = useQuery<{ languages: ILanguage[] }>(
  LANGUAGES_CODES,
  () => ({
    codes: languageCode.value,
  }),
  () => ({
    enabled: languageCode.value !== undefined,
  })
);

const languages = computed(() => languagesResult.value?.languages);

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => user.value?.email ?? ""),
});

const isEmailChangeModalActive = ref(false);
const isRoleChangeModalActive = ref(false);
const isConfirmationModalActive = ref(false);

const newUser = reactive({
  email: "",
  role: user.value?.role,
  confirm: false,
  notify: true,
});

const metadata = computed(
  (): Array<{ key: string; value: string; type?: string }> => {
    if (!user.value) return [];
    return [
      {
        key: t("Email"),
        value: user.value.email,
        type: "email",
      },
      {
        key: t("Language"),
        value: languages.value ? languages.value[0].name : t("Unknown"),
      },
      {
        key: t("Role"),
        value: roleName(user.value.role),
        type: "role",
      },
      {
        key: t("Login status"),
        value: user.value.disabled ? t("Disabled") : t("Activated"),
      },
      {
        key: t("Confirmed"),
        value: user.value.confirmedAt
          ? formatDateTimeString(user.value.confirmedAt)
          : t("Not confirmed"),
        type: "confirmed",
      },
      {
        key: t("Last sign-in"),
        value: user.value.currentSignInAt
          ? formatDateTimeString(user.value.currentSignInAt)
          : t("Unknown"),
      },
      {
        key: t("Last IP adress"),
        value: user.value.currentSignInIp || t("Unknown"),
        type: user.value.currentSignInIp ? "ip" : undefined,
      },
      {
        key: t("Total number of participations"),
        value: user.value.participations.total.toString(),
      },
      {
        key: t("Uploaded media total size"),
        value: formatBytes(user.value.mediaSize),
      },
    ];
  }
);

const roleName = (role: ICurrentUserRole): string => {
  switch (role) {
    case ICurrentUserRole.ADMINISTRATOR:
      return t("Administrator");
    case ICurrentUserRole.MODERATOR:
      return t("Moderator");
    case ICurrentUserRole.USER:
    default:
      return t("User");
  }
};

const router = useRouter();

const { mutate: suspendUser } = useMutation<
  { suspendProfile: { id: string } },
  { userId: string }
>(SUSPEND_USER);

const dialog = inject<Dialog>("dialog");

const suspendAccount = async (): Promise<void> => {
  dialog?.confirm({
    title: t("Suspend the account?"),
    message: t(
      "Do you really want to suspend this account? All of the user's profiles will be deleted."
    ),
    confirmText: t("Suspend the account"),
    cancelText: t("Cancel"),
    variant: "danger",
    onConfirm: async () => {
      suspendUser({
        userId: props.id,
      });
      return router.push({ name: RouteName.USERS });
    },
  });
};

const profiles = computed((): IPerson[] | undefined => {
  return user.value?.actors;
});

const confirmUser = async () => {
  isConfirmationModalActive.value = false;
  await updateUser({
    id: props.id,
    confirmed: true,
    notify: newUser.notify,
  });
};

const updateUserRole = async () => {
  isRoleChangeModalActive.value = false;
  await updateUser({
    id: props.id,
    role: newUser.role,
    notify: newUser.notify,
  });
};

const updateUserEmail = async () => {
  isEmailChangeModalActive.value = false;
  await updateUser({
    id: props.id,
    email: newUser.email,
    notify: newUser.notify,
  });
};

const { mutate: updateUser } = useMutation<
  { adminUpdateUser: IUser },
  {
    id: string;
    email?: string;
    notify: boolean;
    confirmed?: boolean;
    role?: ICurrentUserRole;
  }
>(ADMIN_UPDATE_USER);

watch(user, (updatedUser: IUser | undefined, oldUser: IUser | undefined) => {
  if (updatedUser?.role !== oldUser?.role) {
    newUser.role = updatedUser?.role;
  }
});

const userEmailDomain = computed((): string | undefined => {
  if (user.value?.email) {
    return user.value?.email.split("@")[1];
  }
  return undefined;
});
</script>
