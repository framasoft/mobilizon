<template>
  <section class="container mx-auto pt-4 max-w-2xl">
    <h1>
      {{ $t("Resend confirmation email") }}
    </h1>
    <o-notification v-if="error" variant="danger">
      {{ errorMessage }}
    </o-notification>
    <form v-if="!validationSent" @submit="resendConfirmationAction">
      <o-field :label="$t('Email address')" labelFor="emailAddress">
        <o-input
          aria-required="true"
          required
          type="email"
          id="emailAddress"
          v-model="emailValue"
        />
      </o-field>
      <p class="flex flex-wrap gap-1 mt-2">
        <o-button variant="primary" native-type="submit">
          {{ $t("Send the confirmation email again") }}
        </o-button>
        <o-button
          variant="primary"
          outlined
          tag="router-link"
          :to="{ name: RouteName.LOGIN }"
          >{{ $t("Cancel") }}</o-button
        >
      </p>
    </form>
    <div v-else>
      <o-notification variant="success" :closable="false" title="Success">
        {{
          $t(
            "If an account with this email exists, we just sent another confirmation email to {email}",
            { email: emailValue }
          )
        }}
      </o-notification>
      <o-notification variant="info" class="mt-2">
        {{
          $t("Please check your spam folder if you didn't receive the email.")
        }}
      </o-notification>
    </div>
  </section>
</template>

<script lang="ts" setup>
import { RESEND_CONFIRMATION_EMAIL } from "@/graphql/auth";
import RouteName from "@/router/name";
import { ref, computed } from "vue";
import { useMutation } from "@vue/apollo-composable";
import { useI18n } from "vue-i18n";
import { useHead } from "@vueuse/head";

const { t } = useI18n({ useScope: "global" });
useHead({
  title: computed(() => t("Resend confirmation email")),
  meta: [{ name: "robots", content: "noindex" }],
});

const props = withDefaults(defineProps<{ email: string }>(), { email: "" });
const defaultEmail = computed(() => props.email);

const emailValue = ref<string>(defaultEmail.value);

const validationSent = ref(false);
const error = ref(false);
const errorMessage = ref<string>();

const {
  mutate: resendConfirmationEmail,
  onDone: resentConfirmationEmail,
  onError: resentConfirmationEmailError,
} = useMutation(RESEND_CONFIRMATION_EMAIL);

resentConfirmationEmail(() => {
  validationSent.value = true;
});

resentConfirmationEmailError((err) => {
  console.error(err);
  error.value = true;
  errorMessage.value = err.graphQLErrors[0].message;
});

const resendConfirmationAction = async (e: Event): Promise<void> => {
  e.preventDefault();
  error.value = false;

  resendConfirmationEmail({
    email: emailValue.value,
  });
};
</script>
