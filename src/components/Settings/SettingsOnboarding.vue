<template>
  <div v-if="loggedUser">
    <section>
      <div class="setting-title">
        <h2>{{ t("Settings") }}</h2>
      </div>
      <div>
        <h3>{{ t("Language") }}</h3>
        <p>
          {{
            t(
              "This setting will be used to display the website and send you emails in the correct language."
            )
          }}
        </p>
        <div class="has-text-centered">
          <o-select
            :loading="loading"
            v-model="locale"
            :placeholder="t('Select a language')"
          >
            <option v-for="(language, lang) in langs" :value="lang" :key="lang">
              {{ language }}
            </option>
          </o-select>
        </div>
      </div>

      <div>
        <h3>{{ t("Timezone") }}</h3>
        <p>
          {{
            t(
              "We use your timezone to make sure you get notifications for an event at the correct time."
            )
          }}
          {{
            t("Your timezone was detected as {timezone}.", {
              timezone,
            })
          }}
          <o-notification
            variant="danger"
            v-if="!loading && !supportedTimezone"
          >
            {{ t("Your timezone {timezone} isn't supported.", { timezone }) }}
          </o-notification>
        </p>
      </div>
    </section>
  </div>
</template>
<script lang="ts" setup>
import { useTimezones } from "@/composition/apollo/config";
import {
  doUpdateSetting,
  updateLocale,
  useLoggedUser,
} from "@/composition/apollo/user";
import { saveLocaleData } from "@/utils/auth";
import { computed, onMounted, watch } from "vue";
import { useI18n } from "vue-i18n";
import langs from "../../i18n/langs.json";

const { timezones, loading } = useTimezones();

const { t, locale } = useI18n({ useScope: "global" });

const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;

const { loggedUser } = useLoggedUser();

const { mutate: doUpdateLocale } = updateLocale();

onMounted(() => {
  doUpdateLocale({ locale: locale as unknown as string });
  doUpdateSetting({ timezone });
});

watch(locale, () => {
  if (locale.value) {
    doUpdateLocale({ locale: locale as unknown as string });
    saveLocaleData(locale.value as string);
  }
});

const supportedTimezone = computed((): boolean => {
  return (timezones.value ?? []).includes(timezone);
});
</script>
<style lang="scss" scoped>
h3 {
  font-weight: bold;
}
</style>
