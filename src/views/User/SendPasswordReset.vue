<template>
  <section class="container mx-auto">
    <h1>
      {{ t("Forgot your password?") }}
    </h1>
    <p>
      {{
        t(
          "Enter your email address below, and we'll email you instructions on how to change your password."
        )
      }}
    </p>
    <o-notification
      title="Error"
      variant="danger"
      v-for="error in errors"
      :key="error"
      @close="removeError(error)"
    >
      {{ error }}
    </o-notification>
    <form @submit="sendResetPasswordTokenAction" v-if="!validationSent">
      <o-field :label="t('Email address')">
        <o-input
          aria-required="true"
          required
          type="email"
          v-model="emailValue"
          expanded
        />
      </o-field>
      <p class="my-4 flex gap-2">
        <o-button variant="primary" native-type="submit">
          {{ t("Submit") }}
        </o-button>
        <o-button
          tag="router-link"
          :to="{ name: RouteName.LOGIN }"
          variant="text"
          >{{ t("Cancel") }}</o-button
        >
      </p>
    </form>
    <div v-else>
      <o-notification variant="success" :closable="false" title="Success">
        {{
          t("We just sent an email to {email}", {
            email: emailValue,
          })
        }}
      </o-notification>
      <o-notification variant="info">
        {{
          t("Please check your spam folder if you didn't receive the email.")
        }}
      </o-notification>
    </div>
  </section>
</template>

<script lang="ts" setup>
import { SEND_RESET_PASSWORD } from "../../graphql/auth";
import RouteName from "../../router/name";
import { computed, ref } from "vue";
import { useMutation } from "@vue/apollo-composable";
import { useHead } from "@unhead/vue";
import { useI18n } from "vue-i18n";

const { t } = useI18n({ useScope: "global" });
useHead({
  title: computed(() => t("Reset password")),
});

const props = withDefaults(
  defineProps<{
    email?: string;
  }>(),
  { email: "" }
);

const defaultEmail = computed(() => props.email);
const emailValue = ref<string>(defaultEmail.value);

const validationSent = ref(false);

const errors = ref<string[]>([]);

const removeError = (message: string): void => {
  errors.value.splice(errors.value.indexOf(message));
};

const {
  mutate: sendResetPasswordMutation,
  onDone: sendResetPasswordDone,
  onError: sendResetPasswordError,
} = useMutation(SEND_RESET_PASSWORD);

sendResetPasswordDone(() => {
  validationSent.value = true;
});
sendResetPasswordError((err) => {
  console.error(err);
  if (err.graphQLErrors) {
    err.graphQLErrors.forEach(({ message }: { message: string }) => {
      if (errors.value.indexOf(message) < 0) {
        errors.value.push(message);
      }
    });
  }
});

const sendResetPasswordTokenAction = async (e: Event): Promise<void> => {
  e.preventDefault();

  sendResetPasswordMutation({
    email: emailValue.value,
  });
};
</script>
