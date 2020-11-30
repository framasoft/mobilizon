<template>
  <div v-if="loggedUser">
    <section>
      <div class="setting-title">
        <h2>{{ $t("Settings") }}</h2>
      </div>
      <div>
        <h3>{{ $t("Language") }}</h3>
        <p>
          {{
            $t(
              "This setting will be used to display the website and send you emails in the correct language."
            )
          }}
        </p>
        <div class="has-text-centered">
          <b-select
            :loading="!config || !loggedUser"
            v-model="locale"
            :placeholder="$t('Select a language')"
          >
            <option v-for="(language, lang) in langs" :value="lang" :key="lang">
              {{ language }}
            </option>
          </b-select>
        </div>
      </div>

      <div>
        <h3>{{ $t("Timezone") }}</h3>
        <p>
          {{
            $t(
              "We use your timezone to make sure you get notifications for an event at the correct time."
            )
          }}
          {{
            $t("Your timezone was detected as {timezone}.", {
              timezone,
            })
          }}
          <b-message
            type="is-danger"
            v-if="!$apollo.loading && !supportedTimezone"
          >
            {{ $t("Your timezone {timezone} isn't supported.", { timezone }) }}
          </b-message>
        </p>
      </div>
    </section>
  </div>
</template>
<script lang="ts">
import { Component, Watch } from "vue-property-decorator";
import { TIMEZONES } from "@/graphql/config";
import { IConfig } from "@/types/config.model";
import { saveLocaleData } from "@/utils/auth";
import { mixins } from "vue-class-component";
import Onboarding from "@/mixins/onboarding";
import { UPDATE_USER_LOCALE } from "../../graphql/user";
import langs from "../../i18n/langs.json";

@Component({
  apollo: {
    config: TIMEZONES,
  },
})
export default class SettingsOnboarding extends mixins(Onboarding) {
  config!: IConfig;

  notificationOnDay = true;

  locale: string | null = this.$i18n.locale;

  langs: Record<string, string> = langs;

  timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;

  mounted(): void {
    this.doUpdateLocale(this.$i18n.locale);
    this.doUpdateSetting({ timezone: this.timezone });
  }

  @Watch("locale")
  async updateLocale(): Promise<void> {
    if (this.locale) {
      this.doUpdateLocale(this.locale);
      saveLocaleData(this.locale);
    }
  }

  private async doUpdateLocale(locale: string): Promise<void> {
    await this.$apollo.mutate({
      mutation: UPDATE_USER_LOCALE,
      variables: {
        locale,
      },
    });
  }

  get supportedTimezone(): boolean {
    return this.config && this.config.timezones.includes(this.timezone);
  }
}
</script>
<style lang="scss" scoped>
h3 {
  font-weight: bold;
}
</style>
