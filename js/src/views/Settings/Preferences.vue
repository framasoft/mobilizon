<template>
  <div>
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
    <span>{{
      $t("Timezone detected as {timezone}.", {
        timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
      })
    }}</span>
  </div>
</template>
<script lang="ts">
import { Component, Vue, Watch } from "vue-property-decorator";
import { TIMEZONES } from "../../graphql/config";
import { USER_SETTINGS, SET_USER_SETTINGS } from "../../graphql/user";
import { IConfig } from "../../types/config.model";
import { ICurrentUser } from "../../types/current-user.model";

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

  @Watch("loggedUser")
  setSavedTimezone(loggedUser: ICurrentUser) {
    if (loggedUser && loggedUser.settings.timezone) {
      this.selectedTimezone = loggedUser.settings.timezone;
    } else {
      this.selectedTimezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
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

  @Watch("selectedTimezone")
  async updateTimezone() {
    await this.$apollo.mutate<{ setUserSetting: string }>({
      mutation: SET_USER_SETTINGS,
      variables: {
        timezone: this.selectedTimezone,
      },
    });
  }
}
</script>
