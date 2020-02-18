<template>
  <section v-if="adminSettings">
    <form @submit.prevent="updateSettings">
      <b-field :label="$t('Instance Name')">
        <b-input v-model="adminSettings.instanceName" />
      </b-field>
      <b-field :label="$t('Instance Description')">
        <b-input type="textarea" v-model="adminSettings.instanceDescription" />
      </b-field>
      <b-field :label="$t('Allow registrations')">
        <b-switch v-model="adminSettings.registrationsOpen">
          <p class="content" v-if="adminSettings.registrationsOpen">
            {{ $t("Registration is allowed, anyone can register.") }}
          </p>
          <p class="content" v-else>{{ $t("Registration is closed.") }}</p>
        </b-switch>
      </b-field>
      <b-field :label="$t('Instance Terms Source')">
        <div class="columns">
          <div class="column is-one-third-desktop">
            <b-field>
              <b-radio
                v-model="adminSettings.instanceTermsType"
                name="instanceTermsType"
                :native-value="InstanceTermsType.DEFAULT"
                >{{ $t("Default Mobilizon.org terms") }}</b-radio
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
              v-if="adminSettings.instanceTermsType === InstanceTermsType.DEFAULT"
            >
              <b>{{ $t("Default") }}</b>
              <i18n
                tag="p"
                class="content"
                path="The {default_terms} will be used. They will be translated in the user's language."
              >
                <a
                  slot="default_terms"
                  href="https://mobilizon.org/terms"
                  target="_blank"
                  rel="noopener"
                  >{{ $t("default Mobilizon terms") }}</a
                >
              </i18n>
            </div>
            <div
              class="notification"
              v-if="adminSettings.instanceTermsType === InstanceTermsType.URL"
            >
              <b>{{ $t("URL") }}</b>
              <p class="content">{{ $t("Set an URL to a page with your own terms.") }}</p>
            </div>
            <div
              class="notification"
              v-if="adminSettings.instanceTermsType === InstanceTermsType.CUSTOM"
            >
              <b>{{ $t("Custom") }}</b>
              <p class="content">
                {{
                  $t(
                    "Enter your own terms. HTML tags allowed. Mobilizon.org's terms are provided as template."
                  )
                }}
              </p>
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
      <b-button native-type="submit" type="is-primary">{{ $t("Save") }}</b-button>
    </form>
  </section>
</template>
<script lang="ts">
import { Component, Vue } from "vue-property-decorator";
import { ADMIN_SETTINGS, SAVE_ADMIN_SETTINGS } from "@/graphql/admin";
import { IAdminSettings, InstanceTermsType } from "@/types/admin.model";
import RouteName from "../../router/name";

@Component({
  apollo: {
    adminSettings: ADMIN_SETTINGS,
  },
})
export default class Settings extends Vue {
  adminSettings!: IAdminSettings;

  InstanceTermsType = InstanceTermsType;

  RouteName = RouteName;

  async updateSettings() {
    try {
      await this.$apollo.mutate({
        mutation: SAVE_ADMIN_SETTINGS,
        variables: {
          ...this.adminSettings,
        },
      });
      this.$notifier.success(this.$t("Admin settings successfully saved.") as string);
    } catch (e) {
      console.error(e);
      this.$notifier.error(this.$t("Failed to save admin settings") as string);
    }
  }
}
</script>
