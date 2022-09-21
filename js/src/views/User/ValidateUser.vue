<template>
  <section class="container mx-auto">
    <h1 class="title" v-if="loading">
      {{ $t("Your account is being validated") }}
    </h1>
    <div v-else>
      <div v-if="failed">
        <o-notification
          :title="$t('Error while validating account')"
          variant="danger"
        >
          {{
            $t(
              "Either the account is already validated, either the validation token is incorrect."
            )
          }}
        </o-notification>
      </div>
      <h1 class="title" v-else>{{ $t("Your account has been validated") }}</h1>
    </div>
  </section>
</template>

<script lang="ts" setup>
import { ICurrentUserRole } from "@/types/enums";
import { VALIDATE_USER, UPDATE_CURRENT_USER_CLIENT } from "../../graphql/user";
import RouteName from "../../router/name";
import { saveUserData, saveTokenData } from "../../utils/auth";
import { changeIdentity } from "../../utils/identity";
import { ref, onBeforeMount, computed } from "vue";
import { useRouter } from "vue-router";
import { useMutation } from "@vue/apollo-composable";
import { IUser } from "@/types/current-user.model";
import { useHead } from "@vueuse/head";
import { useI18n } from "vue-i18n";

const { t } = useI18n({ useScope: "global" });
useHead({
  title: computed(() => t("Validating account")),
});

const props = defineProps<{
  token: string;
}>();

const loading = ref(true);
const failed = ref(false);

onBeforeMount(() => {
  validateAction({ token: props.token });
});

const router = useRouter();

const user = ref<IUser | null>(null);

const {
  mutate: validateAction,
  onDone: onValidatingUserMutationDone,
  onError: onValidatingUserMutationError,
} = useMutation(VALIDATE_USER);

const {
  onDone: onUpdatingCurrentUserClientDone,
  mutate: updateCurrentUserClient,
} = useMutation(UPDATE_CURRENT_USER_CLIENT);

onUpdatingCurrentUserClientDone(async () => {
  if (user.value?.defaultActor) {
    await changeIdentity(user.value?.defaultActor);
    await router.push({ name: RouteName.HOME });
  } else {
    // If the user didn't register any profile yet, let's create one for them
    await router.push({
      name: RouteName.REGISTER_PROFILE,
      params: { email: user.value?.email, userAlreadyActivated: "true" },
    });
  }
});

onValidatingUserMutationDone(async ({ data }) => {
  if (data) {
    saveUserData(data.validateUser);
    saveTokenData(data.validateUser);

    const { user: validatedUser } = data.validateUser;
    user.value = validatedUser;

    updateCurrentUserClient({
      id: validatedUser.id,
      email: validatedUser.email,
      isLoggedIn: true,
      role: ICurrentUserRole.USER,
    });
  }
});

onValidatingUserMutationError((error) => {
  console.error(error);
  failed.value = true;
  loading.value = false;
});
</script>
