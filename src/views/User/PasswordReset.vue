<template>
  <section class="container mx-auto">
    <h1 class="">
      {{ $t("Password reset") }}
    </h1>
    <o-notification
      :title="$t('Error')"
      variant="danger"
      v-for="error in errors"
      :key="error"
      >{{ error }}</o-notification
    >
    <form @submit="resetAction">
      <o-field :label="$t('Password')">
        <o-input
          aria-required="true"
          required
          type="password"
          password-reveal
          minlength="6"
          v-model="credentials.password"
          expanded
        />
      </o-field>
      <o-field :label="$t('Password (confirmation)')">
        <o-input
          aria-required="true"
          required
          type="password"
          password-reveal
          minlength="6"
          v-model="credentials.passwordConfirmation"
          expanded
        />
      </o-field>
      <button class="button is-primary">
        {{ $t("Reset my password") }}
      </button>
    </form>
  </section>
</template>

<script lang="ts" setup>
import { RESET_PASSWORD } from "@/graphql/auth";
import { saveUserData } from "@/utils/auth";
import { ILogin } from "@/types/login.model";
import RouteName from "@/router/name";
import { reactive, ref, computed } from "vue";
import { useMutation } from "@vue/apollo-composable";
import { useRouter } from "vue-router";
import { useHead } from "@unhead/vue";
import { useI18n } from "vue-i18n";

const props = defineProps<{ token: string }>();

const { t } = useI18n({ useScope: "global" });
useHead({ title: computed(() => t("Password reset")) });

const credentials = reactive<{
  password: string;
  passwordConfirmation: string;
}>({
  password: "",
  passwordConfirmation: "",
});

const errors = ref<string[]>([]);

// rules = {
//   passwordLength: (value: string): boolean | string =>
//     value.length > 6 || "Password must be at least 6 characters long",
//   required: validateRequiredField,
//   passwordEqual: (value: string): boolean | string =>
//     value === this.credentials.password || "Passwords must be the same",
// };

// get samePasswords(): boolean {
//   return (
//     this.rules.passwordLength(this.credentials.password) === true &&
//     this.credentials.password === this.credentials.passwordConfirmation
//   );
// }

const router = useRouter();

const {
  mutate: resetPasswordMutation,
  onDone: resetPasswordMutationDone,
  onError: resetPasswordMutationError,
} = useMutation<{ resetPassword: ILogin }>(RESET_PASSWORD);

resetPasswordMutationDone(({ data }) => {
  if (data == null) {
    throw new Error("Data is undefined");
  }

  saveUserData(data.resetPassword);
  router.push({ name: RouteName.HOME });
  return;
});

resetPasswordMutationError((err) => {
  err.graphQLErrors.forEach(({ message }: { message: any }) => {
    errors.value.push(message);
  });
});

const resetAction = (e: Event) => {
  e.preventDefault();
  errors.value.splice(0);

  resetPasswordMutation({
    password: credentials.password,
    token: props.token,
  });
};
</script>
