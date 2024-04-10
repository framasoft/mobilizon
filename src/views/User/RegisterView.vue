<template>
  <div class="container mx-auto py-6">
    <section class="">
      <h1>
        {{
          t("Register an account on {instanceName}!", {
            instanceName: config?.name,
          })
        }}
      </h1>
      <i18n-t
        tag="p"
        keypath="{instanceName} is an instance of the {mobilizon} software."
      >
        <template #instanceName>
          <b>{{ config?.name }}</b>
        </template>
        <template #mobilizon>
          <a href="https://joinmobilizon.org" target="_blank" class="out">{{
            t("Mobilizon")
          }}</a>
        </template>
      </i18n-t>
    </section>
    <section class="flex flex-wrap gap-6">
      <div class="">
        <div class="my-4">
          <h2 class="text-xl">{{ t("Why create an account?") }}</h2>
          <div class="prose dark:prose-invert">
            <ul>
              <li>{{ t("To create and manage your events") }}</li>
              <li>
                {{
                  t(
                    "To create and manage multiples identities from a same account"
                  )
                }}
              </li>
              <li>
                {{
                  t(
                    "To register for an event by choosing one of your identities"
                  )
                }}
              </li>
              <li v-if="config?.features.groups">
                {{
                  t(
                    "To create or join an group and start organizing with other people"
                  )
                }}
              </li>
              <li v-if="config?.features.groups">
                {{
                  t("To follow groups and be informed of their latest events")
                }}
              </li>
            </ul>
          </div>
        </div>
        <router-link class="out block my-4" :to="{ name: RouteName.ABOUT }">{{
          t("Learn more")
        }}</router-link>
        <hr role="presentation" />
        <div class="my-4">
          <h2 class="text-xl">
            {{ t("About {instance}", { instance: config?.name }) }}
          </h2>
          <div
            class="prose dark:prose-invert"
            v-html="config?.description"
          ></div>
          <i18n-t
            keypath="Please read the {fullRules} published by {instance}'s administrators."
            tag="p"
            ><template #fullRules>
              <router-link class="out" :to="{ name: RouteName.RULES }">{{
                t("full rules")
              }}</router-link>
            </template>
            <template #instance>
              <b>{{ config?.name }}</b>
            </template>
          </i18n-t>
        </div>
      </div>
      <div class="">
        <o-notification variant="warning" v-if="config?.registrationsAllowlist">
          {{ t("Registrations are restricted by allowlisting.") }}
        </o-notification>
        <form @submit.prevent="submit">
          <o-field
            :label="t('Email')"
            :variant="errorEmailType"
            :message="errorEmailMessage"
            label-for="email"
          >
            <o-input
              aria-required="true"
              required
              id="email"
              type="email"
              v-model="credentials.email"
              expanded
            />
          </o-field>

          <o-field
            :label="t('Password')"
            :type="errorPasswordType"
            :message="errorPasswordMessage"
            label-for="password"
          >
            <o-input
              aria-required="true"
              required
              id="password"
              type="password"
              password-reveal
              minlength="6"
              v-model="credentials.password"
              expanded
            />
          </o-field>

          <div class="flex items-start mb-6 mt-2">
            <div class="flex items-center h-5">
              <input
                type="checkbox"
                id="accept_rules_terms"
                class="w-4 h-4 bg-gray-50 rounded border border-gray-300 focus:ring-3 focus:ring-blue-300 dark:bg-gray-700 dark:border-gray-600 dark:focus:ring-blue-600 dark:ring-offset-gray-800"
                required
              />
            </div>

            <label
              for="accept_rules_terms"
              class="ml-2 text-gray-900 dark:text-gray-300"
            >
              <i18n-t
                tag="span"
                keypath="I agree to the {instanceRules} and {termsOfService}"
              >
                <template #instanceRules>
                  <router-link class="out" :to="{ name: RouteName.RULES }">{{
                    t("instance rules")
                  }}</router-link>
                </template>
                <template #termsOfService>
                  <router-link class="out" :to="{ name: RouteName.TERMS }">{{
                    t("terms of service")
                  }}</router-link>
                </template>
              </i18n-t>
            </label>
          </div>

          <p>
            <o-button
              variant="primary"
              size="large"
              :disabled="sendingForm"
              native-type="submit"
            >
              {{ t("Create an account") }}
            </o-button>
          </p>

          <p class="my-6">
            <o-button
              tag="router-link"
              variant="text"
              :to="{
                name: RouteName.RESEND_CONFIRMATION,
                params: { email: credentials.email },
              }"
              >{{ t("Didn't receive the instructions?") }}</o-button
            >
            <o-button
              tag="router-link"
              variant="text"
              :to="{
                name: RouteName.LOGIN,
                query: {
                  email: credentials.email,
                  password: credentials.password,
                },
              }"
              >{{ t("Login") }}</o-button
            >
          </p>

          <hr role="presentation" />
          <div
            class="control"
            v-if="config && config.auth.oauthProviders.length > 0"
          >
            <auth-providers :oauthProviders="config.auth.oauthProviders" />
          </div>
        </form>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import { CREATE_USER } from "../../graphql/user";
import RouteName from "../../router/name";
import { IConfig } from "../../types/config.model";
import { CONFIG } from "../../graphql/config";
import AuthProviders from "../../components/User/AuthProviders.vue";
import { computed, reactive, ref, watch } from "vue";
import { useMutation, useQuery } from "@vue/apollo-composable";
import { useI18n } from "vue-i18n";
import { useRoute, useRouter } from "vue-router";
import { useHead } from "@/utils/head";
import { AbsintheGraphQLErrors } from "@/types/errors.model";

type errorType = "danger" | "warning";
type errorMessage = { type: errorType; message: string };
type credentialsType = { email: string; password: string; locale: string };

const { t, locale } = useI18n({ useScope: "global" });
const route = useRoute();
const router = useRouter();

const { result: configResult } = useQuery<{ config: IConfig }>(CONFIG);

const config = computed(() => configResult.value?.config);

const credentials = reactive<credentialsType>({
  email: typeof route.query.email === "string" ? route.query.email : "",
  password:
    typeof route.query.password === "string" ? route.query.password : "",
  locale: "en",
});

const emailErrors = ref<errorMessage[]>([]);
const passwordErrors = ref<errorMessage[]>([]);

const sendingForm = ref(false);

const title = computed((): string => {
  if (config.value) {
    return t("Register an account on {instanceName}!", {
      instanceName: config.value?.name,
    });
  }
  return "";
});

useHead({
  title: () => title.value,
});

const { onDone, onError, mutate } = useMutation(CREATE_USER);

onDone(() => {
  router.push({
    name: RouteName.REGISTER_PROFILE,
    params: { email: credentials.email },
  });
});

onError((error) => {
  (error.graphQLErrors as AbsintheGraphQLErrors).forEach(
    ({ field, message }) => {
      switch (field) {
        case "email":
          emailErrors.value.push({
            type: "danger" as errorType,
            message: message[0] as string,
          });
          break;
        case "password":
          passwordErrors.value.push({
            type: "danger" as errorType,
            message: message[0] as string,
          });
          break;
        default:
      }
    }
  );
  sendingForm.value = false;
});

const submit = async (): Promise<void> => {
  sendingForm.value = true;
  credentials.locale = locale as unknown as string;
  try {
    emailErrors.value = [];
    passwordErrors.value = [];

    mutate(credentials);
  } catch (error: any) {
    console.error(error);

    sendingForm.value = false;
  }
};

watch(credentials, () => {
  if (credentials.email !== credentials.email.toLowerCase()) {
    const error = {
      type: "warning" as errorType,
      message: t(
        "Emails usually don't contain capitals, make sure you haven't made a typo."
      ),
    };
    emailErrors.value = [error];
  }
});

const maxErrorType = (errors: errorMessage[]): errorType | undefined => {
  if (!errors || errors.length === 0) return undefined;
  return errors.reduce<errorType>((acc, error) => {
    if (error.type === "danger" || acc === "danger") return "danger";
    return "warning";
  }, "warning");
};

const errorEmailType = computed((): errorType | undefined => {
  return maxErrorType(emailErrors.value);
});

const errorPasswordType = computed((): errorType | undefined => {
  return maxErrorType(passwordErrors.value);
});

const errorEmailMessage = computed((): string => {
  return emailErrors.value.map(({ message }) => message).join(" ");
});

const errorPasswordMessage = computed((): string => {
  return passwordErrors.value?.map(({ message }) => message).join(" ");
});
</script>
