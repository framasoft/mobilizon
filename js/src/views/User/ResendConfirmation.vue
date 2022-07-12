<template>
  <section class="container mx-auto pt-4 max-w-2xl">
    <h1>
      {{ $t("Resend confirmation email") }}
    </h1>
    <form v-if="!validationSent" @submit="resendConfirmationAction">
      <o-field :label="$t('Email address')">
        <o-input
          aria-required="true"
          required
          type="email"
          v-model="credentials.email"
        />
      </o-field>
      <p class="flex flex-wrap gap-1">
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
            { email: credentials.email }
          )
        }}
      </o-notification>
      <o-notification variant="info">
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
import { reactive, ref, computed } from "vue";
import { useMutation } from "@vue/apollo-composable";
import { useI18n } from "vue-i18n";
import { useHead } from "@vueuse/head";

const { t } = useI18n({ useScope: "global" });
useHead({
  title: computed(() => t("Resend confirmation email")),
  meta: [{ name: "robots", content: "noindex" }],
});

const props = withDefaults(defineProps<{ email: string }>(), { email: "" });

const credentials = reactive({
  email: props.email,
});

const validationSent = ref(false);
const error = ref(false);

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
});

const resendConfirmationAction = async (e: Event): Promise<void> => {
  e.preventDefault();
  error.value = false;

  resendConfirmationEmail({
    email: credentials.email,
  });
};
</script>
