<template>
  <div>
    <nav class="breadcrumb" aria-label="breadcrumbs">
      <ul>
        <li>
          <router-link :to="{ name: RouteName.ACCOUNT_SETTINGS }">{{ $t("Account") }}</router-link>
        </li>
        <li class="is-active">
          <router-link :to="{ name: RouteName.PREFERENCES }">{{ $t("Preferences") }}</router-link>
        </li>
      </ul>
    </nav>
    <div>
      <b-field :label="$t('Language')">
        <b-select
          :loading="!config || !loggedUser"
          v-model="$i18n.locale"
          :placeholder="$t('Select a language')"
        >
          <option v-for="(language, lang) in languages" :value="lang" :key="lang">
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
          <optgroup :label="group" v-for="(groupTimezones, group) in timezones" :key="group">
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
      <em>{{
        $t("Timezone detected as {timezone}.", {
          timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
        })
      }}</em>
    </div>
  </div>
</template>
<script lang="ts">
import { Component, Vue, Watch } from "vue-property-decorator";
import { TIMEZONES } from "../../graphql/config";
import { USER_SETTINGS, SET_USER_SETTINGS, UPDATE_USER_LOCALE } from "../../graphql/user";
import { IConfig } from "../../types/config.model";
import { ICurrentUser } from "../../types/current-user.model";
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

  loggedUser!: ICurrentUser;

  selectedTimezone: string | null = null;

  locale: string | null = null;

  RouteName = RouteName;

  @Watch("loggedUser")
  setSavedTimezone(loggedUser: ICurrentUser) {
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

  sanitize(timezone: string): string {
    return timezone.split("_").join(" ").replace("St ", "St. ").split("/").join(" - ");
  }

  get timezones() {
    if (!this.config || !this.config.timezones) return {};
    return this.config.timezones.reduce((acc: { [key: string]: Array<string> }, val: string) => {
      const components = val.split("/");
      const [prefix, suffix] = [components.shift() as string, components.join("/")];
      const pushOrCreate = (
        acc: { [key: string]: Array<string> },
        prefix: string,
        suffix: string
      ) => {
        (acc[prefix] = acc[prefix] || []).push(suffix);
        return acc;
      };
      if (suffix) {
        return pushOrCreate(acc, prefix, suffix);
      }
      return pushOrCreate(acc, this.$t("Other") as string, prefix);
    }, {});
  }

  get languages(): object {
    return this.$i18n.availableLocales.reduce((acc: object, lang: string) => {
      // @ts-ignore
      if (langs[lang]) {
        return {
          ...acc,
          // @ts-ignore
          [lang]: langs[lang],
        };
      }
      return acc;
    }, {} as object);
  }

  @Watch("selectedTimezone")
  async updateTimezone() {
    if (this.selectedTimezone !== this.loggedUser.settings.timezone) {
      await this.$apollo.mutate<{ setUserSetting: string }>({
        mutation: SET_USER_SETTINGS,
        variables: {
          timezone: this.selectedTimezone,
        },
      });
    }
  }

  @Watch("$i18n.locale")
  async updateLocale() {
    await this.$apollo.mutate({
      mutation: UPDATE_USER_LOCALE,
      variables: {
        locale: this.$i18n.locale,
      },
    });
  }
}
</script>
