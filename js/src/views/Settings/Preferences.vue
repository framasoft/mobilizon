<template>
  <div>
    <nav class="breadcrumb" aria-label="breadcrumbs">
      <ul>
        <li>
          <router-link :to="{ name: RouteName.ACCOUNT_SETTINGS }">{{
            $t("Account")
          }}</router-link>
        </li>
        <li class="is-active">
          <router-link :to="{ name: RouteName.PREFERENCES }">{{
            $t("Preferences")
          }}</router-link>
        </li>
      </ul>
    </nav>
    <div>
      <b-field :label="$t('Language')">
        <b-select
          :loading="!config || !loggedUser"
          v-model="locale"
          :placeholder="$t('Select a language')"
        >
          <option v-for="(language, lang) in langs" :value="lang" :key="lang">
            {{ language }}
          </option>
        </b-select>
      </b-field>
      <b-field :label="$t('Timezone')">
        <b-select
          :placeholder="$t('Select a timezone')"
          :loading="!config || !loggedUser"
          v-model="selectedTimezone"
        >
          <optgroup
            :label="group"
            v-for="(groupTimezones, group) in timezones"
            :key="group"
          >
            <option
              v-for="timezone in groupTimezones"
              :value="`${group}/${timezone}`"
              :key="timezone"
            >
              {{ sanitize(timezone) }}
            </option>
          </optgroup>
        </b-select>
      </b-field>
      <em v-if="Intl.DateTimeFormat().resolvedOptions().timeZone">{{
        $t("Timezone detected as {timezone}.", {
          timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
        })
      }}</em>
      <b-message v-else type="is-danger">{{
        $t("Unable to detect timezone.")
      }}</b-message>
    </div>
  </div>
</template>
<script lang="ts">
import { Component, Vue, Watch } from "vue-property-decorator";
import { saveLocaleData } from "@/utils/auth";
import { TIMEZONES } from "../../graphql/config";
import {
  USER_SETTINGS,
  SET_USER_SETTINGS,
  UPDATE_USER_LOCALE,
} from "../../graphql/user";
import { IConfig } from "../../types/config.model";
import { IUser } from "../../types/current-user.model";
import langs from "../../i18n/langs.json";
import RouteName from "../../router/name";

@Component({
  apollo: {
    config: TIMEZONES,
    loggedUser: USER_SETTINGS,
  },
})
export default class Preferences extends Vue {
  config!: IConfig;

  loggedUser!: IUser;

  selectedTimezone: string | null = null;

  locale: string | null = null;

  RouteName = RouteName;

  langs: Record<string, string> = langs;

  @Watch("loggedUser")
  setSavedTimezone(loggedUser: IUser): void {
    if (loggedUser && loggedUser.settings.timezone) {
      this.selectedTimezone = loggedUser.settings.timezone;
    } else {
      this.selectedTimezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    }
    if (loggedUser && loggedUser.locale) {
      this.locale = loggedUser.locale;
    } else {
      this.locale = this.$i18n.locale;
    }
  }

  // eslint-disable-next-line class-methods-use-this
  sanitize(timezone: string): string {
    return timezone
      .split("_")
      .join(" ")
      .replace("St ", "St. ")
      .split("/")
      .join(" - ");
  }

  get timezones(): Record<string, string[]> {
    if (!this.config || !this.config.timezones) return {};
    return this.config.timezones.reduce(
      (acc: { [key: string]: Array<string> }, val: string) => {
        const components = val.split("/");
        const [prefix, suffix] = [
          components.shift() as string,
          components.join("/"),
        ];
        const pushOrCreate = (
          acc2: { [key: string]: Array<string> },
          prefix2: string,
          suffix2: string
        ) => {
          // eslint-disable-next-line no-param-reassign
          (acc2[prefix2] = acc2[prefix2] || []).push(suffix2);
          return acc2;
        };
        if (suffix) {
          return pushOrCreate(acc, prefix, suffix);
        }
        return pushOrCreate(acc, this.$t("Other") as string, prefix);
      },
      {}
    );
  }

  @Watch("selectedTimezone")
  async updateTimezone(): Promise<void> {
    if (this.selectedTimezone !== this.loggedUser.settings.timezone) {
      await this.$apollo.mutate<{ setUserSetting: string }>({
        mutation: SET_USER_SETTINGS,
        variables: {
          timezone: this.selectedTimezone,
        },
      });
    }
  }

  @Watch("locale")
  async updateLocale(): Promise<void> {
    if (this.locale) {
      await this.$apollo.mutate({
        mutation: UPDATE_USER_LOCALE,
        variables: {
          locale: this.locale,
        },
      });
      saveLocaleData(this.locale);
    }
  }
}
</script>
