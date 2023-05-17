<template>
  <div v-if="loggedUser">
    <breadcrumbs-nav
      :links="[
        {
          name: RouteName.ACCOUNT_SETTINGS,
          text: t('Account'),
        },
        {
          name: RouteName.ACCOUNT_SETTINGS_GENERAL,
          text: t('General'),
        },
      ]"
    />
    <section>
      <h2>{{ t("Email") }}</h2>
      <i18n-t
        tag="p"
        class="prose dark:prose-invert"
        v-if="loggedUser"
        keypath="Your current email is {email}. You use it to log in."
      >
        <template #email>
          <b>{{ loggedUser.email }}</b>
        </template>
      </i18n-t>
      <o-notification
        v-if="!canChangeEmail && loggedUser.provider"
        variant="warning"
        :closable="false"
      >
        {{
          t(
            "Your email address was automatically set based on your {provider} account.",
            {
              provider: providerName(loggedUser.provider),
            }
          )
        }}
      </o-notification>
      <o-notification
        variant="danger"
        has-icon
        aria-close-label="Close notification"
        role="alert"
        :key="error"
        v-for="error in changeEmailErrors"
        >{{ error }}</o-notification
      >
      <form
        @submit.prevent="resetEmailAction"
        ref="emailForm"
        class="form"
        v-if="canChangeEmail"
      >
        <o-field :label="t('New email')" label-for="account-email">
          <o-input
            aria-required="true"
            required
            type="email"
            id="account-email"
            v-model="newEmail"
          />
        </o-field>
        <p class="help">{{ t("You'll receive a confirmation email.") }}</p>
        <o-field :label="t('Password')" label-for="account-password">
          <o-input
            aria-required="true"
            required
            type="password"
            id="account-password"
            password-reveal
            minlength="6"
            v-model="passwordForEmailChange"
          />
        </o-field>
        <o-button class="mt-2" variant="primary" nativeType="submit">
          {{ t("Change my email") }}
        </o-button>
      </form>
      <h2 class="mt-2">{{ t("Password") }}</h2>
      <o-notification
        v-if="!canChangePassword && loggedUser.provider"
        variant="warning"
        :closable="false"
      >
        {{
          t(
            "You can't change your password because you are registered through {provider}.",
            {
              provider: providerName(loggedUser.provider),
            }
          )
        }}
      </o-notification>
      <o-notification
        variant="danger"
        has-icon
        aria-close-label="Close notification"
        role="alert"
        :key="error"
        v-for="error in changePasswordErrors"
        >{{ error }}</o-notification
      >
      <form
        @submit.prevent="resetPasswordAction"
        ref="passwordForm"
        class="form"
        v-if="canChangePassword"
      >
        <o-field :label="t('Old password')" label-for="account-old-password">
          <o-input
            aria-required="true"
            required
            type="password"
            password-reveal
            minlength="6"
            id="account-old-password"
            v-model="oldPassword"
          />
        </o-field>
        <o-field :label="t('New password')" label-for="account-new-password">
          <o-input
            aria-required="true"
            required
            type="password"
            password-reveal
            minlength="6"
            id="account-new-password"
            v-model="newPassword"
          />
        </o-field>
        <o-button class="mt-2" variant="primary" nativeType="submit">
          {{ t("Change my password") }}
        </o-button>
      </form>
      <h2 class="mt-2">{{ t("Delete account") }}</h2>
      <p class="prose dark:prose-invert">
        {{ t("Deleting my account will delete all of my identities.") }}
      </p>
      <o-button @click="openDeleteAccountModal" variant="danger" class="mb-4">
        {{ t("Delete my account") }}
      </o-button>

      <o-modal
        :close-button-aria-label="t('Close')"
        v-model:active="isDeleteAccountModalActive"
        has-modal-card
        full-screen
        :can-cancel="false"
      >
        <section class="">
          <div class="">
            <div class="container mx-auto max-w-md">
              <div class="">
                <div class="">
                  <h1 class="title">
                    {{ t("Deleting your Mobilizon account") }}
                  </h1>
                  <p class="prose dark:prose-invert">
                    {{
                      t(
                        "Are you really sure you want to delete your whole account? You'll lose everything. Identities, settings, events created, messages and participations will be gone forever."
                      )
                    }}
                    <br />
                    <b>{{ t("There will be no way to recover your data.") }}</b>
                  </p>
                  <p class="prose dark:prose-invert" v-if="hasUserGotAPassword">
                    {{
                      t("Please enter your password to confirm this action.")
                    }}
                  </p>
                  <form @submit.prevent="deleteAccount">
                    <o-field
                      :type="deleteAccountPasswordFieldType"
                      v-if="hasUserGotAPassword"
                      label-for="account-deletion-password"
                    >
                      <o-input
                        type="password"
                        v-model="passwordForAccountDeletion"
                        password-reveal
                        id="account-deletion-password"
                        :aria-label="t('Password')"
                        icon="lock"
                        :placeholder="t('Password')"
                      />
                      <template #message>
                        <o-notification class="mt-2 not-italic text-base"
                          variant="danger"
                          v-for="message in deletePasswordErrors"
                          :key="message"
                        >
                          {{ message }}
                        </o-notification>
                      </template>
                    </o-field>
                    <div class="flex items-center justify-center">
                      <o-button
                        class="mt-2"
                        native-type="submit"
                        variant="danger"
                        size="large"
                      >
                        {{ t("Delete everything") }}
                      </o-button>
                    </div>
                  </form>
                  <div class="mt-4 text-center">
                    <o-button
                      variant="light"
                      @click="isDeleteAccountModalActive = false"
                    >
                      {{ t("Cancel") }}
                    </o-button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>
      </o-modal>
    </section>
  </div>
</template>

<script lang="ts" setup>
import { useLoggedUser } from "@/composition/apollo/user";
import { Notifier } from "@/plugins/notifier";
import { IAuthProvider } from "@/types/enums";
import { useMutation } from "@vue/apollo-composable";
import { useHead } from "@vueuse/head";
import { GraphQLError } from "graphql/error/GraphQLError";
import { computed, inject, ref } from "vue";
import { useI18n } from "vue-i18n";
import { useRouter } from "vue-router";
import {
  CHANGE_EMAIL,
  CHANGE_PASSWORD,
  DELETE_ACCOUNT,
} from "../../graphql/user";
import RouteName from "../../router/name";
import { logout, SELECTED_PROVIDERS } from "../../utils/auth";
import { useProgrammatic } from "@oruga-ui/oruga-next";

const { t } = useI18n({ useScope: "global" });

const { loggedUser } = useLoggedUser();

useHead({
  title: computed(() => t("General settings")),
});

const passwordForm = ref<HTMLFormElement>();
const emailForm = ref<HTMLFormElement>();

const passwordForEmailChange = ref("");
const newEmail = ref("");
const changeEmailErrors = ref<string[]>([]);
const oldPassword = ref("");
const newPassword = ref("");
const changePasswordErrors = ref<string[]>([]);
const deletePasswordErrors = ref<string[]>([]);
const isDeleteAccountModalActive = ref(false);
const passwordForAccountDeletion = ref("");

const notifier = inject<Notifier>("notifier");

const {
  mutate: changeEmailMutation,
  onDone: changeEmailMutationDone,
  onError: changeEmailMutationError,
} = useMutation(CHANGE_EMAIL);

changeEmailMutationDone(() => {
  notifier?.info(
    t(
      "The account's email address was changed. Check your emails to verify it."
    )
  );
  newEmail.value = "";
  passwordForEmailChange.value = "";
});

changeEmailMutationError((err) => {
  handleErrors("email", err);
});

const resetEmailAction = async (): Promise<void> => {
  if (emailForm.value?.reportValidity()) {
    changeEmailErrors.value = [];

    changeEmailMutation({
      email: newEmail.value,
      password: passwordForEmailChange.value,
    });
  }
};

const {
  mutate: changePasswordMutation,
  onDone: onChangePasswordMutationDone,
  onError: onChangePasswordMutationError,
} = useMutation(CHANGE_PASSWORD);

onChangePasswordMutationDone(() => {
  oldPassword.value = "";
  newPassword.value = "";
  notifier?.success(t("The password was successfully changed"));
});

onChangePasswordMutationError((err) => {
  handleErrors("password", err);
});

const resetPasswordAction = async (): Promise<void> => {
  if (passwordForm.value?.reportValidity()) {
    changePasswordErrors.value = [];

    changePasswordMutation({
      oldPassword: oldPassword.value,
      newPassword: newPassword.value,
    });
  }
};

const openDeleteAccountModal = (): void => {
  passwordForAccountDeletion.value = "";
  isDeleteAccountModalActive.value = true;
};

const router = useRouter();

const {
  mutate: deleteAccountMutation,
  onDone: deleteAccountMutationDone,
  onError: deleteAccountMutationError,
} = useMutation<{ deleteAccount: { id: string } }, { password?: string }>(
  DELETE_ACCOUNT
);

const { oruga } = useProgrammatic();

deleteAccountMutationDone(async () => {
  console.debug("Deleted account, logging out client...");
  await logout(false);
  oruga.notification.open({
    message: t("Your account has been successfully deleted"),
    variant: "success",
    position: "bottom-right",
    duration: 5000,
  });

  return router.push({ name: RouteName.HOME });
});

deleteAccountMutationError((err) => {
  deletePasswordErrors.value = err.graphQLErrors.map(
    ({ message }: GraphQLError) => message
  );
});

const deleteAccount = () => {
  deletePasswordErrors.value = [];
  console.debug("Asking to delete account...");
  deleteAccountMutation({
    password: hasUserGotAPassword.value
      ? passwordForAccountDeletion.value
      : undefined,
  });
};

const canChangePassword = computed((): boolean => {
  return !loggedUser.value?.provider;
});

const canChangeEmail = computed((): boolean => {
  return !loggedUser.value?.provider;
});

const providerName = (id: string): string => {
  if (SELECTED_PROVIDERS[id]) {
    return SELECTED_PROVIDERS[id];
  }
  return id;
};

const hasUserGotAPassword = computed((): boolean => {
  return (
    loggedUser.value?.provider == null ||
    loggedUser.value?.provider === IAuthProvider.LDAP
  );
});

const deleteAccountPasswordFieldType = computed((): string | null => {
  return deletePasswordErrors.value.length > 0 ? "is-danger" : null;
});

const handleErrors = (type: string, err: any) => {
  console.error(err);

  if (err.graphQLErrors !== undefined) {
    err.graphQLErrors.forEach(({ message }: { message: string }) => {
      switch (type) {
        case "password":
          changePasswordErrors.value.push(message);
          break;
        case "email":
        default:
          changeEmailErrors.value.push(message);
          break;
      }
    });
  }
};
</script>
