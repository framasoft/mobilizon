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
    <section v-if="adminSettings">
      <form @submit.prevent="updateSettings">
        <b-field :label="$t('Instance Name')">
          <b-input v-model="adminSettings.instanceName" />
        </b-field>
        <div class="field">
          <label class="label has-help">{{
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
            v-model="adminSettings.instanceDescription"
            rows="2"
          />
        </div>
        <div class="field">
          <label class="label has-help">{{ $t("Instance Slogan") }}</label>
          <small>
            {{
              $t(
                'A short tagline for your instance homepage. Defaults to "Gather ⋅ Organize ⋅ Mobilize"'
              )
            }}
          </small>
          <b-input
            v-model="adminSettings.instanceSlogan"
            :placeholder="$t('Gather ⋅ Organize ⋅ Mobilize')"
          />
        </div>
        <div class="field">
          <label class="label has-help">{{ $t("Contact") }}</label>
          <small>
            {{ $t("Can be an email or a link, or just plain text.") }}
          </small>
          <b-input v-model="adminSettings.contact" />
        </div>
        <b-field :label="$t('Allow registrations')">
          <b-switch v-model="adminSettings.registrationsOpen">
            <p class="content" v-if="adminSettings.registrationsOpen">
              {{ $t("Registration is allowed, anyone can register.") }}
            </p>
            <p class="content" v-else>{{ $t("Registration is closed.") }}</p>
          </b-switch>
        </b-field>
        <div class="field">
          <label class="label has-help">{{ $t("Instance languages") }}</label>
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
          >
            <template slot="empty">{{ $t("No languages found") }}</template>
          </b-taginput>
        </div>
        <div class="field">
          <label class="label has-help">{{
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
            v-model="adminSettings.instanceLongDescription"
            rows="4"
          />
        </div>
        <div class="field">
          <label class="label has-help">{{ $t("Instance Rules") }}</label>
          <small>
            {{
              $t(
                "A place for your code of conduct, rules or guidelines. You can use HTML tags."
              )
            }}
          </small>
          <b-input type="textarea" v-model="adminSettings.instanceRules" />
        </div>
        <b-field :label="$t('Instance Terms Source')">
          <div class="columns">
            <div class="column is-one-third-desktop">
              <b-field>
                <b-radio
                  v-model="adminSettings.instanceTermsType"
                  name="instanceTermsType"
                  :native-value="InstanceTermsType.DEFAULT"
                  >{{ $t("Default Mobilizon terms") }}</b-radio
                >
              </b-field>
              <b-field>
                <b-radio
                  v-model="adminSettings.instanceTermsType"
                  name="instanceTermsType"
                  :native-value="InstanceTermsType.URL"
                  >{{ $t("Custom URL") }}</b-radio
                >
              </b-field>
              <b-field>
                <b-radio
                  v-model="adminSettings.instanceTermsType"
                  name="instanceTermsType"
                  :native-value="InstanceTermsType.CUSTOM"
                  >{{ $t("Custom text") }}</b-radio
                >
              </b-field>
            </div>
            <div class="column">
              <div
                class="notification"
                v-if="
                  adminSettings.instanceTermsType === InstanceTermsType.DEFAULT
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
                v-if="adminSettings.instanceTermsType === InstanceTermsType.URL"
              >
                <b>{{ $t("URL") }}</b>
                <p class="content">
                  {{ $t("Set an URL to a page with your own terms.") }}
                </p>
              </div>
              <div
                class="notification"
                v-if="
                  adminSettings.instanceTermsType === InstanceTermsType.CUSTOM
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
          v-if="adminSettings.instanceTermsType === InstanceTermsType.URL"
        >
          <b-input type="URL" v-model="adminSettings.instanceTermsUrl" />
        </b-field>
        <b-field
          :label="$t('Instance Terms')"
          v-if="adminSettings.instanceTermsType === InstanceTermsType.CUSTOM"
        >
          <b-input type="textarea" v-model="adminSettings.instanceTerms" />
        </b-field>
        <b-field :label="$t('Instance Privacy Policy Source')">
          <div class="columns">
            <div class="column is-one-third-desktop">
              <b-field>
                <b-radio
                  v-model="adminSettings.instancePrivacyPolicyType"
                  name="instancePrivacyType"
                  :native-value="InstancePrivacyType.DEFAULT"
                  >{{ $t("Default Mobilizon privacy policy") }}</b-radio
                >
              </b-field>
              <b-field>
                <b-radio
                  v-model="adminSettings.instancePrivacyPolicyType"
                  name="instancePrivacyType"
                  :native-value="InstancePrivacyType.URL"
                  >{{ $t("Custom URL") }}</b-radio
                >
              </b-field>
              <b-field>
                <b-radio
                  v-model="adminSettings.instancePrivacyPolicyType"
                  name="instancePrivacyType"
                  :native-value="InstancePrivacyType.CUSTOM"
                  >{{ $t("Custom text") }}</b-radio
                >
              </b-field>
            </div>
            <div class="column">
              <div
                class="notification"
                v-if="
                  adminSettings.instancePrivacyPolicyType ===
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
                  adminSettings.instancePrivacyPolicyType ===
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
                  adminSettings.instancePrivacyPolicyType ===
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
          v-if="
            adminSettings.instancePrivacyPolicyType === InstancePrivacyType.URL
          "
        >
          <b-input
            type="URL"
            v-model="adminSettings.instancePrivacyPolicyUrl"
          />
        </b-field>
        <b-field
          :label="$t('Instance Privacy Policy')"
          v-if="
            adminSettings.instancePrivacyPolicyType ===
            InstancePrivacyType.CUSTOM
          "
        >
          <b-input
            type="textarea"
            v-model="adminSettings.instancePrivacyPolicy"
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
import { Component, Vue } from "vue-property-decorator";
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
})
export default class Settings extends Vue {
  adminSettings!: IAdminSettings;

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
    const variables = { ...this.adminSettings };
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
.notification a {
  color: $primary !important;
  text-decoration: underline !important;
  text-decoration-color: #fea72b !important;
  text-decoration-thickness: 2px !important;
}

label.label.has-help {
  margin-bottom: 0;
}
</style>
