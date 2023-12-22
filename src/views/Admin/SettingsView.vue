<template>
  <div>
    <breadcrumbs-nav
      :links="[
        { name: RouteName.ADMIN, text: t('Admin') },
        { text: t('Instance settings') },
      ]"
    />

    <section v-if="settingsToWrite">
      <form @submit.prevent="updateSettings">
        <o-field :label="t('Instance Name')" label-for="instance-name">
          <o-input
            v-model="settingsToWrite.instanceName"
            id="instance-name"
            expanded
          />
        </o-field>
        <div class="field flex flex-col">
          <label class="" for="instance-description">{{
            t("Instance Short Description")
          }}</label>
          <small>
            {{
              t(
                "Displayed on homepage and meta tags. Describe what Mobilizon is and what makes this instance special in a single paragraph."
              )
            }}
          </small>
          <o-input
            type="textarea"
            v-model="settingsToWrite.instanceDescription"
            rows="2"
            id="instance-description"
          />
        </div>
        <div class="field flex flex-col">
          <label class="" for="instance-slogan">{{
            t("Instance Slogan")
          }}</label>
          <small>
            {{
              t(
                'A short tagline for your instance homepage. Defaults to "Gather ⋅ Organize ⋅ Mobilize"'
              )
            }}
          </small>
          <o-input
            v-model="settingsToWrite.instanceSlogan"
            :placeholder="t('Gather ⋅ Organize ⋅ Mobilize')"
            id="instance-slogan"
          />
        </div>
        <div class="field flex flex-col">
          <label class="" for="instance-contact">{{ t("Contact") }}</label>
          <small>
            {{ t("Can be an email or a link, or just plain text.") }}
          </small>
          <o-input v-model="settingsToWrite.contact" id="instance-contact" />
        </div>
        <o-field :label="t('Allow registrations')">
          <o-switch v-model="settingsToWrite.registrationsOpen">
            <p
              class="prose dark:prose-invert"
              v-if="settingsToWrite.registrationsOpen"
            >
              {{ t("Registration is allowed, anyone can register.") }}
            </p>
            <p class="prose dark:prose-invert" v-else>
              {{ t("Registration is closed.") }}
            </p>
          </o-switch>
        </o-field>
        <div class="field flex flex-col">
          <label class="" for="instance-languages">{{
            t("Instance languages")
          }}</label>
          <small>
            {{ t("Main languages you/your moderators speak") }}
          </small>
          <o-taginput
            v-model="instanceLanguages"
            :data="filteredLanguages"
            allow-autocomplete
            :open-on-focus="true"
            field="name"
            icon="label"
            :placeholder="t('Select languages')"
            @input="getFilteredLanguages"
            id="instance-languages"
          >
            <template #empty>{{ t("No languages found") }}</template>
          </o-taginput>
        </div>
        <div class="field flex flex-col">
          <label class="" for="instance-long-description">{{
            t("Instance Long Description")
          }}</label>
          <small>
            {{
              t(
                "A place to explain who you are and the things that set your instance apart. You can use HTML tags."
              )
            }}
          </small>
          <o-input
            type="textarea"
            v-model="settingsToWrite.instanceLongDescription"
            rows="4"
            id="instance-long-description"
          />
        </div>
        <div class="field flex flex-col">
          <label class="" for="instance-rules">{{ t("Instance Rules") }}</label>
          <small>
            {{
              t(
                "A place for your code of conduct, rules or guidelines. You can use HTML tags."
              )
            }}
          </small>
          <o-input
            type="textarea"
            v-model="settingsToWrite.instanceRules"
            id="instance-rules"
          />
        </div>
        <o-field :label="t('Instance Terms Source')">
          <div class="">
            <div class="">
              <fieldset>
                <legend>
                  {{ t("Choose the source of the instance's Terms") }}
                </legend>
                <o-field>
                  <o-radio
                    v-model="settingsToWrite.instanceTermsType"
                    name="instanceTermsType"
                    :native-value="InstanceTermsType.DEFAULT"
                    >{{ t("Default Mobilizon terms") }}</o-radio
                  >
                </o-field>
                <o-field>
                  <o-radio
                    v-model="settingsToWrite.instanceTermsType"
                    name="instanceTermsType"
                    :native-value="InstanceTermsType.URL"
                    >{{ t("Custom URL") }}</o-radio
                  >
                </o-field>
                <o-field>
                  <o-radio
                    v-model="settingsToWrite.instanceTermsType"
                    name="instanceTermsType"
                    :native-value="InstanceTermsType.CUSTOM"
                    >{{ t("Custom text") }}</o-radio
                  >
                </o-field>
              </fieldset>
            </div>
            <div class="">
              <o-notification
                class="bg-slate-700"
                v-if="
                  settingsToWrite.instanceTermsType ===
                  InstanceTermsType.DEFAULT
                "
              >
                <b>{{ t("Default") }}</b>
                <i18n-t
                  tag="p"
                  class="prose dark:prose-invert"
                  keypath="The {default_terms} will be used. They will be translated in the user's language."
                >
                  <template #default_terms>
                    <a
                      href="https://demo.mobilizon.org/terms"
                      target="_blank"
                      rel="noopener"
                      >{{ t("default Mobilizon terms") }}</a
                    >
                  </template>
                </i18n-t>
                <b>{{
                  t(
                    "NOTE! The default terms have not been checked over by a lawyer and thus are unlikely to provide full legal protection for all situations for an instance admin using them. They are also not specific to all countries and jurisdictions. If you are unsure, please check with a lawyer."
                  )
                }}</b>
              </o-notification>
              <div
                class="notification"
                v-if="
                  settingsToWrite.instanceTermsType === InstanceTermsType.URL
                "
              >
                <b>{{ t("URL") }}</b>
                <p class="prose dark:prose-invert">
                  {{ t("Set an URL to a page with your own terms.") }}
                </p>
              </div>
              <div
                class="notification"
                v-if="
                  settingsToWrite.instanceTermsType === InstanceTermsType.CUSTOM
                "
              >
                <b>{{ t("Custom") }}</b>
                <i18n-t
                  tag="p"
                  class="prose dark:prose-invert"
                  keypath="Enter your own terms. HTML tags allowed. The {mobilizon_terms} are provided as template."
                >
                  <template #mobilizon_terms>
                    <a
                      href="https://demo.mobilizon.org/terms"
                      target="_blank"
                      rel="noopener"
                    >
                      {{ t("default Mobilizon terms") }}</a
                    >
                  </template>
                </i18n-t>
              </div>
            </div>
          </div>
        </o-field>
        <o-field
          :label="t('Instance Terms URL')"
          label-for="instanceTermsUrl"
          v-if="settingsToWrite.instanceTermsType === InstanceTermsType.URL"
        >
          <o-input
            type="URL"
            v-model="settingsToWrite.instanceTermsUrl"
            id="instanceTermsUrl"
          />
        </o-field>
        <o-field
          :label="t('Instance Terms')"
          label-for="instanceTerms"
          v-if="settingsToWrite.instanceTermsType === InstanceTermsType.CUSTOM"
        >
          <o-input
            type="textarea"
            v-model="settingsToWrite.instanceTerms"
            id="instanceTerms"
          />
        </o-field>
        <o-field :label="t('Instance Privacy Policy Source')">
          <div class="">
            <div class="">
              <fieldset>
                <legend>
                  {{ t("Choose the source of the instance's Privacy Policy") }}
                </legend>
                <o-field>
                  <o-radio
                    v-model="settingsToWrite.instancePrivacyPolicyType"
                    name="instancePrivacyType"
                    :native-value="InstancePrivacyType.DEFAULT"
                    >{{ t("Default Mobilizon privacy policy") }}</o-radio
                  >
                </o-field>
                <o-field>
                  <o-radio
                    v-model="settingsToWrite.instancePrivacyPolicyType"
                    name="instancePrivacyType"
                    :native-value="InstancePrivacyType.URL"
                    >{{ t("Custom URL") }}</o-radio
                  >
                </o-field>
                <o-field>
                  <o-radio
                    v-model="settingsToWrite.instancePrivacyPolicyType"
                    name="instancePrivacyType"
                    :native-value="InstancePrivacyType.CUSTOM"
                    >{{ t("Custom text") }}</o-radio
                  >
                </o-field>
              </fieldset>
            </div>
            <div class="">
              <div
                class="notification"
                v-if="
                  settingsToWrite.instancePrivacyPolicyType ===
                  InstancePrivacyType.DEFAULT
                "
              >
                <b>{{ t("Default") }}</b>
                <i18n-t
                  tag="p"
                  class="prose dark:prose-invert"
                  keypath="The {default_privacy_policy} will be used. They will be translated in the user's language."
                >
                  <template #default_privacy_policy>
                    <a
                      href="https://demo.mobilizon.org/privacy"
                      target="_blank"
                      rel="noopener"
                      >{{ t("default Mobilizon privacy policy") }}</a
                    >
                  </template>
                </i18n-t>
              </div>
              <div
                class="notification"
                v-if="
                  settingsToWrite.instancePrivacyPolicyType ===
                  InstancePrivacyType.URL
                "
              >
                <b>{{ t("URL") }}</b>
                <p class="prose dark:prose-invert">
                  {{ t("Set an URL to a page with your own privacy policy.") }}
                </p>
              </div>
              <div
                class="notification"
                v-if="
                  settingsToWrite.instancePrivacyPolicyType ===
                  InstancePrivacyType.CUSTOM
                "
              >
                <b>{{ t("Custom") }}</b>
                <i18n-t
                  tag="p"
                  class="prose dark:prose-invert"
                  keypath="Enter your own privacy policy. HTML tags allowed. The {mobilizon_privacy_policy} is provided as template."
                >
                  <template #mobilizon_privacy_policy>
                    <a
                      href="https://demo.mobilizon.org/privacy"
                      target="_blank"
                      rel="noopener"
                    >
                      {{ t("default Mobilizon privacy policy") }}</a
                    >
                  </template>
                </i18n-t>
              </div>
            </div>
          </div>
        </o-field>
        <o-field
          :label="t('Instance Privacy Policy URL')"
          label-for="instancePrivacyPolicyUrl"
          v-if="
            settingsToWrite.instancePrivacyPolicyType ===
            InstancePrivacyType.URL
          "
        >
          <o-input
            type="URL"
            v-model="settingsToWrite.instancePrivacyPolicyUrl"
            id="instancePrivacyPolicyUrl"
          />
        </o-field>
        <o-field
          :label="t('Instance Privacy Policy')"
          label-for="instancePrivacyPolicy"
          v-if="
            settingsToWrite.instancePrivacyPolicyType ===
            InstancePrivacyType.CUSTOM
          "
        >
          <o-input
            type="textarea"
            v-model="settingsToWrite.instancePrivacyPolicy"
            id="instancePrivacyPolicy"
          />
        </o-field>
        <o-button native-type="submit" variant="primary">{{
          t("Save")
        }}</o-button>
      </form>
    </section>
  </div>
</template>
<script lang="ts" setup>
import {
  ADMIN_SETTINGS,
  SAVE_ADMIN_SETTINGS,
  LANGUAGES,
} from "@/graphql/admin";
import { InstancePrivacyType, InstanceTermsType } from "@/types/enums";
import { IAdminSettings, ILanguage } from "@/types/admin.model";
import RouteName from "@/router/name";
import { useMutation, useQuery } from "@vue/apollo-composable";
import { ref, computed, watch, inject } from "vue";
import { useI18n } from "vue-i18n";
import { useHead } from "@unhead/vue";
import type { Notifier } from "@/plugins/notifier";

const defaultAdminSettings: IAdminSettings = {
  instanceName: "",
  instanceDescription: "",
  instanceSlogan: "",
  instanceLongDescription: "",
  contact: "",
  instanceTerms: "",
  instanceTermsType: InstanceTermsType.DEFAULT,
  instanceTermsUrl: null,
  instancePrivacyPolicy: "",
  instancePrivacyPolicyType: InstancePrivacyType.DEFAULT,
  instancePrivacyPolicyUrl: null,
  instanceRules: "",
  registrationsOpen: false,
  instanceLanguages: [],
};

const { result: adminSettingsResult } = useQuery<{
  adminSettings: IAdminSettings;
}>(ADMIN_SETTINGS);
const adminSettings = computed(
  () => adminSettingsResult.value?.adminSettings ?? defaultAdminSettings
);

const { result: languageResult } = useQuery<{ languages: ILanguage[] }>(
  LANGUAGES
);
const languages = computed(() => languageResult.value?.languages);

const { t } = useI18n({ useScope: "global" });
useHead({
  title: computed(() => t("Settings")),
});

const settingsToWrite = ref<IAdminSettings>(defaultAdminSettings);

watch(adminSettings, () => {
  settingsToWrite.value = { ...adminSettings.value };
});

const filteredLanguages = ref<string[]>([]);

const instanceLanguages = computed({
  get() {
    const languageCodes = [...(adminSettings.value?.instanceLanguages ?? [])];
    return languageCodes
      .map((code) => languageForCode(code))
      .filter((language) => language) as string[];
  },
  set(newInstanceLanguages: string[]) {
    const newFilteredInstanceLanguages = newInstanceLanguages
      .map((language) => {
        return codeForLanguage(language);
      })
      .filter((code) => code !== undefined) as string[];
    settingsToWrite.value = {
      ...settingsToWrite.value,
      instanceLanguages: newFilteredInstanceLanguages,
    };
  },
});

const notifier = inject<Notifier>("notifier");

const {
  mutate: saveAdminSettings,
  onDone: saveAdminSettingsDone,
  onError: saveAdminSettingsError,
} = useMutation(SAVE_ADMIN_SETTINGS);

saveAdminSettingsDone(() => {
  notifier?.success(t("Admin settings successfully saved.") as string);
});

saveAdminSettingsError((e) => {
  console.error(e);
  notifier?.error(t("Failed to save admin settings") as string);
});

const updateSettings = async (): Promise<void> => {
  const variables = { ...settingsToWrite.value };
  console.debug("updating settings with variables", variables);
  saveAdminSettings(variables);
};

const getFilteredLanguages = (text: string): void => {
  filteredLanguages.value = languages.value
    ? languages.value
        .filter((language: ILanguage) => {
          return (
            language.name
              .toString()
              .toLowerCase()
              .indexOf(text.toLowerCase()) >= 0
          );
        })
        .map(({ name }) => name)
    : [];
};

const codeForLanguage = (language: string): string | undefined => {
  if (languages.value) {
    const lang = languages.value.find(({ name }) => name === language);
    if (lang) return lang.code;
  }
  return undefined;
};

const languageForCode = (codeGiven: string): string | undefined => {
  if (languages.value) {
    const lang = languages.value.find(({ code }) => code === codeGiven);
    if (lang) return lang.name;
  }
  return undefined;
};
</script>
<style lang="scss" scoped>
label.label.has-help {
  margin-bottom: 0;
}
</style>
