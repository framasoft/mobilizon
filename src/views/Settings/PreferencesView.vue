<template>
  <div>
    <breadcrumbs-nav
      :links="[
        {
          name: RouteName.ACCOUNT_SETTINGS,
          text: t('Account'),
        },
        {
          name: RouteName.PREFERENCES,
          text: t('Preferences'),
        },
      ]"
    />
    <div>
      <o-field :label="t('Theme')" addonsClass="flex flex-col">
        <o-field>
          <o-checkbox v-model="systemTheme">{{
            t("Adapt to system theme")
          }}</o-checkbox>
        </o-field>
        <o-field>
          <fieldset>
            <legend class="sr-only">{{ t("Theme") }}</legend>
            <o-radio
              :class="{ 'border-mbz-bluegreen': theme === 'light' }"
              class="p-4 bg-white text-zinc-800 rounded-md mt-2 mr-2 border-2"
              :disabled="systemTheme"
              v-model="theme"
              name="theme"
              native-value="light"
              >{{ t("Light") }}</o-radio
            >
            <o-radio
              :class="{ 'border-mbz-bluegreen': theme === 'dark' }"
              class="p-4 bg-zinc-800 rounded-md text-white mt-2 ml-2 border-2"
              :disabled="systemTheme"
              v-model="theme"
              name="theme"
              native-value="dark"
              >{{ t("Dark") }}</o-radio
            >
          </fieldset>
        </o-field>
      </o-field>
      <o-field :label="t('Language')" label-for="setting-language">
        <o-select
          :loading="loadingTimezones || loadingUserSettings"
          v-model="$i18n.locale"
          @update:modelValue="updateLanguage"
          :placeholder="t('Select a language')"
          id="setting-language"
        >
          <option v-for="(language, lang) in langs" :value="lang" :key="lang">
            {{ language }}
          </option>
        </o-select>
      </o-field>
      <o-field
        :label="t('Timezone')"
        v-if="selectedTimezone"
        label-for="setting-timezone"
      >
        <o-select
          :placeholder="t('Select a timezone')"
          :loading="loadingTimezones || loadingUserSettings"
          v-model="selectedTimezone"
          id="setting-timezone"
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
        </o-select>
      </o-field>
      <em v-if="Intl.DateTimeFormat().resolvedOptions().timeZone">{{
        t("Timezone detected as {timezone}.", {
          timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
        })
      }}</em>
      <o-notification v-else variant="danger">{{
        t("Unable to detect timezone.")
      }}</o-notification>
      <hr role="presentation" />
      <o-field grouped>
        <o-field :label="t('City or region')" expanded label-for="setting-city">
          <full-address-auto-complete
            :resultType="AddressSearchType.ADMINISTRATIVE"
            v-model="address"
            :default-text="address?.description"
            id="setting-city"
            class="grid"
            :hideMap="true"
            :hideSelected="true"
            labelClass="sr-only"
            :placeholder="t('e.g. Nantes, Berlin, Cork, …')"
          />
        </o-field>
        <o-field :label="t('Radius')" label-for="setting-radius">
          <o-select
            :placeholder="t('Select a radius')"
            v-model="locationRange"
            id="setting-radius"
          >
            <option
              v-for="index in [1, 5, 10, 25, 50, 100]"
              :key="index"
              :value="index"
            >
              {{ t("{count} km", { count: index }, index) }}
            </option>
          </o-select>
        </o-field>
        <o-button
          :disabled="address == undefined"
          @click="resetArea"
          @keyup.enter="resetArea"
          class="reset-area self-center"
          icon-left="close"
          :aria-label="t('Reset')"
        />
      </o-field>
      <p>
        {{
          t(
            "Your city or region and the radius will only be used to suggest you events nearby. The event radius will consider the administrative center of the area."
          )
        }}
      </p>
    </div>
  </div>
</template>
<script lang="ts" setup>
import ngeohash from "ngeohash";
import { USER_SETTINGS, SET_USER_SETTINGS } from "../../graphql/user";
import langs from "../../i18n/langs.json";
import RouteName from "../../router/name";
import { AddressSearchType } from "@/types/enums";
import { Address, IAddress } from "@/types/address.model";
import { useTimezones } from "@/composition/apollo/config";
import { useUserSettings, updateLocale } from "@/composition/apollo/user";
import { useHead } from "@unhead/vue";
import { computed, defineAsyncComponent, ref, watch } from "vue";
import { useI18n } from "vue-i18n";
import { useMutation } from "@vue/apollo-composable";

const FullAddressAutoComplete = defineAsyncComponent(
  () => import("@/components/Event/FullAddressAutoComplete.vue")
);

const { timezones: serverTimezones, loading: loadingTimezones } =
  useTimezones();
const { loggedUser, loading: loadingUserSettings } = useUserSettings();

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => t("Preferences")),
});

// langs: Record<string, string> = langs;

const theme = ref(localStorage.getItem("theme"));
const systemTheme = ref(!("theme" in localStorage));

const { mutate: doUpdateLocale } = updateLocale();

const updateLanguage = (newLocale: string) => {
  doUpdateLocale({ locale: newLocale });
};

watch(systemTheme, (newSystemTheme) => {
  console.debug("changing system theme", newSystemTheme);
  if (newSystemTheme) {
    theme.value = null;
    localStorage.removeItem("theme");
  } else {
    theme.value = "light";
    localStorage.setItem("theme", theme.value);
  }
  changeTheme();
});

watch(theme, (newTheme) => {
  console.debug("changing theme value", newTheme);
  if (newTheme) {
    localStorage.setItem("theme", newTheme);
  }
  changeTheme();
});

const changeTheme = () => {
  console.debug("changing theme to apply");
  if (
    localStorage.getItem("theme") === "dark" ||
    (!("theme" in localStorage) &&
      window.matchMedia("(prefers-color-scheme: dark)").matches)
  ) {
    console.debug("applying dark theme");
    document.documentElement.classList.add("dark");
  } else {
    console.debug("removing dark theme");
    document.documentElement.classList.remove("dark");
  }
};

const selectedTimezone = computed({
  get() {
    if (loggedUser.value?.settings?.timezone) {
      return loggedUser.value.settings.timezone;
    }
    const detectedTimezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    if (loggedUser.value?.settings?.timezone === null) {
      updateUserSettings({ timezone: detectedTimezone });
    }
    return detectedTimezone;
  },
  set(newSelectedTimezone: string) {
    if (newSelectedTimezone !== loggedUser.value?.settings?.timezone) {
      updateUserSettings({ timezone: newSelectedTimezone });
    }
  },
});

const sanitize = (timezone: string): string => {
  return timezone
    .split("_")
    .join(" ")
    .replace("St ", "St. ")
    .split("/")
    .join(" - ");
};

const timezones = computed((): Record<string, string[]> => {
  if (!serverTimezones.value) return {};
  return serverTimezones.value.reduce(
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
      return pushOrCreate(acc, t("Other") as string, prefix);
    },
    {}
  );
});

const address = computed({
  get(): IAddress | null {
    if (
      loggedUser.value?.settings?.location?.name &&
      loggedUser.value?.settings?.location?.geohash
    ) {
      const { latitude, longitude } = ngeohash.decode(
        loggedUser.value?.settings?.location?.geohash
      );
      const name = loggedUser.value?.settings?.location?.name;
      return {
        description: name,
        locality: "",
        type: "administrative",
        geom: `${longitude};${latitude}`,
        street: "",
        postalCode: "",
        region: "",
        country: "",
      };
    }
    return null;
  },
  set(newAddress: IAddress | null) {
    if (newAddress?.geom) {
      const { geom } = newAddress;
      const addressObject = new Address(newAddress);
      const queryText = addressObject.poiInfos.name;
      const [lon, lat] = geom.split(";");
      const geohash = ngeohash.encode(lat, lon, 6);
      if (queryText && geom) {
        updateUserSettings({
          location: {
            geohash,
            name: queryText,
          },
        });
      }
    }
  },
});

const locationRange = computed({
  get(): number | undefined | null {
    return loggedUser.value?.settings?.location?.range;
  },
  set(newLocationRange: number | undefined | null) {
    if (newLocationRange) {
      updateUserSettings({
        location: {
          range: newLocationRange,
        },
      });
    }
  },
});

const resetArea = (): void => {
  updateUserSettings({
    location: {
      geohash: null,
      name: null,
      range: null,
    },
  });
};

const { mutate: updateUserSettings } = useMutation<{ setUserSetting: string }>(
  SET_USER_SETTINGS,
  () => ({
    refetchQueries: [{ query: USER_SETTINGS }],
  })
);
</script>
<style lang="scss" scoped>
.reset-area {
  align-self: center;
  position: relative;
  top: 10px;
}
</style>
