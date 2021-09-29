<template>
  <div>
    <nav class="breadcrumb" aria-label="breadcrumbs">
      <ul>
        <li>
          <router-link :to="{ name: RouteName.ADMIN }">{{
            $t("Admin")
          }}</router-link>
        </li>
        <li class="is-active">
          <router-link :to="{ name: RouteName.ADMIN_SETTINGS }">{{
            $t("Instance settings")
          }}</router-link>
        </li>
      </ul>
    </nav>
    <section v-if="settingsToWrite">
      <form @submit.prevent="updateSettings">
        <b-field :label="$t('Instance Name')" label-for="instance-name">
          <b-input v-model="settingsToWrite.instanceName" id="instance-name" />
        </b-field>
        <div class="field">
          <label class="label has-help" for="instance-description">{{
            $t("Instance Short Description")
          }}</label>
          <small>
            {{
              $t(
                "Displayed on homepage and meta tags. Describe what Mobilizon is and what makes this instance special in a single paragraph."
              )
            }}
          </small>
          <b-input
            type="textarea"
            v-model="settingsToWrite.instanceDescription"
            rows="2"
            id="instance-description"
          />
        </div>
        <div class="field">
          <label class="label has-help" for="instance-slogan">{{
            $t("Instance Slogan")
          }}</label>
          <small>
            {{
              $t(
                'A short tagline for your instance homepage. Defaults to "Gather ⋅ Organize ⋅ Mobilize"'
              )
            }}
          </small>
          <b-input
            v-model="settingsToWrite.instanceSlogan"
            :placeholder="$t('Gather ⋅ Organize ⋅ Mobilize')"
            id="instance-slogan"
          />
        </div>
        <div class="field">
          <label class="label has-help" for="instance-contact">{{
            $t("Contact")
          }}</label>
          <small>
            {{ $t("Can be an email or a link, or just plain text.") }}
          </small>
          <b-input v-model="settingsToWrite.contact" id="instance-contact" />
        </div>
        <b-field :label="$t('Allow registrations')">
          <b-switch v-model="settingsToWrite.registrationsOpen">
            <p class="content" v-if="settingsToWrite.registrationsOpen">
              {{ $t("Registration is allowed, anyone can register.") }}
            </p>
            <p class="content" v-else>{{ $t("Registration is closed.") }}</p>
          </b-switch>
        </b-field>
        <div class="field">
          <label class="label has-help" for="instance-languages">{{
            $t("Instance languages")
          }}</label>
          <small>
            {{ $t("Main languages you/your moderators speak") }}
          </small>
          <b-taginput
            v-model="instanceLanguages"
            :data="filteredLanguages"
            autocomplete
            :open-on-focus="true"
            field="name"
            icon="label"
            :placeholder="$t('Select languages')"
            @typing="getFilteredLanguages"
            id="instance-languages"
          >
            <template slot="empty">{{ $t("No languages found") }}</template>
          </b-taginput>
        </div>
        <div class="field">
          <label class="label has-help" for="instance-long-description">{{
            $t("Instance Long Description")
          }}</label>
          <small>
            {{
              $t(
                "A place to explain who you are and the things that set your instance apart. You can use HTML tags."
              )
            }}
          </small>
          <b-input
            type="textarea"
            v-model="settingsToWrite.instanceLongDescription"
            rows="4"
            id="instance-long-description"
          />
        </div>
        <div class="field">
          <label class="label has-help" for="instance-rules">{{
            $t("Instance Rules")
          }}</label>
          <small>
            {{
              $t(
                "A place for your code of conduct, rules or guidelines. You can use HTML tags."
              )
            }}
          </small>
          <b-input
            type="textarea"
            v-model="settingsToWrite.instanceRules"
            id="instance-rules"
          />
        </div>
        <b-field :label="$t('Instance Terms Source')">
          <div class="columns">
            <div class="column is-one-third-desktop">
              <fieldset>
                <legend>
                  {{ $t("Choose the source of the instance's Terms") }}
                </legend>
                <b-field>
                  <b-radio
                    v-model="settingsToWrite.instanceTermsType"
                    name="instanceTermsType"
                    :native-value="InstanceTermsType.DEFAULT"
                    >{{ $t("Default Mobilizon terms") }}</b-radio
                  >
                </b-field>
                <b-field>
                  <b-radio
                    v-model="settingsToWrite.instanceTermsType"
                    name="instanceTermsType"
                    :native-value="InstanceTermsType.URL"
                    >{{ $t("Custom URL") }}</b-radio
                  >
                </b-field>
                <b-field>
                  <b-radio
                    v-model="settingsToWrite.instanceTermsType"
                    name="instanceTermsType"
                    :native-value="InstanceTermsType.CUSTOM"
                    >{{ $t("Custom text") }}</b-radio
                  >
                </b-field>
              </fieldset>
            </div>
            <div class="column">
              <div
                class="notification"
                v-if="
                  settingsToWrite.instanceTermsType ===
                  InstanceTermsType.DEFAULT
                "
              >
                <b>{{ $t("Default") }}</b>
                <i18n
                  tag="p"
                  class="content"
                  path="The {default_terms} will be used. They will be translated in the user's language."
                >
                  <a
                    slot="default_terms"
                    href="https://demo.mobilizon.org/terms"
                    target="_blank"
                    rel="noopener"
                    >{{ $t("default Mobilizon terms") }}</a
                  >
                </i18n>
                <b>{{
                  $t(
                    "NOTE! The default terms have not been checked over by a lawyer and thus are unlikely to provide full legal protection for all situations for an instance admin using them. They are also not specific to all countries and jurisdictions. If you are unsure, please check with a lawyer."
                  )
                }}</b>
              </div>
              <div
                class="notification"
                v-if="
                  settingsToWrite.instanceTermsType === InstanceTermsType.URL
                "
              >
                <b>{{ $t("URL") }}</b>
                <p class="content">
                  {{ $t("Set an URL to a page with your own terms.") }}
                </p>
              </div>
              <div
                class="notification"
                v-if="
                  settingsToWrite.instanceTermsType === InstanceTermsType.CUSTOM
                "
              >
                <b>{{ $t("Custom") }}</b>
                <i18n
                  tag="p"
                  class="content"
                  path="Enter your own terms. HTML tags allowed. The {mobilizon_terms} are provided as template."
                >
                  <a
                    slot="mobilizon_terms"
                    href="https://demo.mobilizon.org/terms"
                    target="_blank"
                    rel="noopener"
                  >
                    {{ $t("default Mobilizon terms") }}</a
                  >
                </i18n>
              </div>
            </div>
          </div>
        </b-field>
        <b-field
          :label="$t('Instance Terms URL')"
          label-for="instanceTermsUrl"
          v-if="settingsToWrite.instanceTermsType === InstanceTermsType.URL"
        >
          <b-input
            type="URL"
            v-model="settingsToWrite.instanceTermsUrl"
            id="instanceTermsUrl"
          />
        </b-field>
        <b-field
          :label="$t('Instance Terms')"
          label-for="instanceTerms"
          v-if="settingsToWrite.instanceTermsType === InstanceTermsType.CUSTOM"
        >
          <b-input
            type="textarea"
            v-model="settingsToWrite.instanceTerms"
            id="instanceTerms"
          />
        </b-field>
        <b-field :label="$t('Instance Privacy Policy Source')">
          <div class="columns">
            <div class="column is-one-third-desktop">
              <fieldset>
                <legend>
                  {{ $t("Choose the source of the instance's Privacy Policy") }}
                </legend>
                <b-field>
                  <b-radio
                    v-model="settingsToWrite.instancePrivacyPolicyType"
                    name="instancePrivacyType"
                    :native-value="InstancePrivacyType.DEFAULT"
                    >{{ $t("Default Mobilizon privacy policy") }}</b-radio
                  >
                </b-field>
                <b-field>
                  <b-radio
                    v-model="settingsToWrite.instancePrivacyPolicyType"
                    name="instancePrivacyType"
                    :native-value="InstancePrivacyType.URL"
                    >{{ $t("Custom URL") }}</b-radio
                  >
                </b-field>
                <b-field>
                  <b-radio
                    v-model="settingsToWrite.instancePrivacyPolicyType"
                    name="instancePrivacyType"
                    :native-value="InstancePrivacyType.CUSTOM"
                    >{{ $t("Custom text") }}</b-radio
                  >
                </b-field>
              </fieldset>
            </div>
            <div class="column">
              <div
                class="notification"
                v-if="
                  settingsToWrite.instancePrivacyPolicyType ===
                  InstancePrivacyType.DEFAULT
                "
              >
                <b>{{ $t("Default") }}</b>
                <i18n
                  tag="p"
                  class="content"
                  path="The {default_privacy_policy} will be used. They will be translated in the user's language."
                >
                  <a
                    slot="default_privacy_policy"
                    href="https://demo.mobilizon.org/privacy"
                    target="_blank"
                    rel="noopener"
                    >{{ $t("default Mobilizon privacy policy") }}</a
                  >
                </i18n>
              </div>
              <div
                class="notification"
                v-if="
                  settingsToWrite.instancePrivacyPolicyType ===
                  InstancePrivacyType.URL
                "
              >
                <b>{{ $t("URL") }}</b>
                <p class="content">
                  {{ $t("Set an URL to a page with your own privacy policy.") }}
                </p>
              </div>
              <div
                class="notification"
                v-if="
                  settingsToWrite.instancePrivacyPolicyType ===
                  InstancePrivacyType.CUSTOM
                "
              >
                <b>{{ $t("Custom") }}</b>
                <i18n
                  tag="p"
                  class="content"
                  path="Enter your own privacy policy. HTML tags allowed. The {mobilizon_privacy_policy} is provided as template."
                >
                  <a
                    slot="mobilizon_privacy_policy"
                    href="https://demo.mobilizon.org/privacy"
                    target="_blank"
                    rel="noopener"
                  >
                    {{ $t("default Mobilizon privacy policy") }}</a
                  >
                </i18n>
              </div>
            </div>
          </div>
        </b-field>
        <b-field
          :label="$t('Instance Privacy Policy URL')"
          label-for="instancePrivacyPolicyUrl"
          v-if="
            settingsToWrite.instancePrivacyPolicyType ===
            InstancePrivacyType.URL
          "
        >
          <b-input
            type="URL"
            v-model="settingsToWrite.instancePrivacyPolicyUrl"
            id="instancePrivacyPolicyUrl"
          />
        </b-field>
        <b-field
          :label="$t('Instance Privacy Policy')"
          label-for="instancePrivacyPolicy"
          v-if="
            settingsToWrite.instancePrivacyPolicyType ===
            InstancePrivacyType.CUSTOM
          "
        >
          <b-input
            type="textarea"
            v-model="settingsToWrite.instancePrivacyPolicy"
            id="instancePrivacyPolicy"
          />
        </b-field>
        <b-button native-type="submit" type="is-primary">{{
          $t("Save")
        }}</b-button>
      </form>
    </section>
  </div>
</template>
<script lang="ts">
import { Component, Vue, Watch } from "vue-property-decorator";
import {
  ADMIN_SETTINGS,
  SAVE_ADMIN_SETTINGS,
  LANGUAGES,
} from "@/graphql/admin";
import { InstancePrivacyType, InstanceTermsType } from "@/types/enums";
import { IAdminSettings, ILanguage } from "../../types/admin.model";
import RouteName from "../../router/name";

@Component({
  apollo: {
    adminSettings: ADMIN_SETTINGS,
    languages: LANGUAGES,
  },
  metaInfo() {
    return {
      title: this.$t("Settings") as string,
    };
  },
})
export default class Settings extends Vue {
  adminSettings: IAdminSettings = {
    instanceName: "",
    instanceDescription: "",
    instanceSlogan: "",
    instanceLongDescription: "",
    contact: "",
    instanceTerms: "",
    instanceTermsType: InstanceTermsType.DEFAULT,
    instanceTermsUrl: null,
    instancePrivacyPolicy: "",
    instancePrivacyPolicyType: InstanceTermsType.DEFAULT,
    instancePrivacyPolicyUrl: null,
    instanceRules: "",
    registrationsOpen: false,
    instanceLanguages: [],
  };

  settingsToWrite: IAdminSettings = { ...this.adminSettings };

  @Watch("adminSettings")
  updateSettingsToWrite(): void {
    this.settingsToWrite = { ...this.adminSettings };
  }

  languages!: ILanguage[];

  filteredLanguages: string[] = [];

  InstanceTermsType = InstanceTermsType;

  InstancePrivacyType = InstancePrivacyType;

  RouteName = RouteName;

  get instanceLanguages(): string[] {
    const languageCodes = this.adminSettings.instanceLanguages || [];
    return languageCodes
      .map((code) => this.languageForCode(code))
      .filter((language) => language) as string[];
  }

  set instanceLanguages(instanceLanguages: string[]) {
    this.adminSettings.instanceLanguages = instanceLanguages
      .map((language) => {
        return this.codeForLanguage(language);
      })
      .filter((code) => code !== undefined) as string[];
  }

  async updateSettings(): Promise<void> {
    const variables = { ...this.settingsToWrite };
    try {
      await this.$apollo.mutate({
        mutation: SAVE_ADMIN_SETTINGS,
        variables,
      });
      this.$notifier.success(
        this.$t("Admin settings successfully saved.") as string
      );
    } catch (e) {
      console.error(e);
      this.$notifier.error(this.$t("Failed to save admin settings") as string);
    }
  }

  getFilteredLanguages(text: string): void {
    this.filteredLanguages = this.languages
      ? this.languages
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
  }

  private codeForLanguage(language: string): string | undefined {
    if (this.languages) {
      const lang = this.languages.find(({ name }) => name === language);
      if (lang) return lang.code;
    }
    return undefined;
  }

  private languageForCode(codeGiven: string): string | undefined {
    if (this.languages) {
      const lang = this.languages.find(({ code }) => code === codeGiven);
      if (lang) return lang.name;
    }
    return undefined;
  }
}
</script>
<style lang="scss" scoped>
label.label.has-help {
  margin-bottom: 0;
}
</style>
