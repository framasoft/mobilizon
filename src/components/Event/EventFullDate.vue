<template>
  <p v-if="!endsOn">
    <span>{{
      formatDateTimeString(beginsOn, timezoneToShow, showStartTime)
    }}</span>
  </p>
  <!-- endsOn is set and isSameDay() -->
  <template v-else-if="isSameDay()">
    <p v-if="showStartTime && showEndTime">
      <span>{{
        t("On {date} from {startTime} to {endTime}", {
          date: formatDate(beginsOn),
          startTime: formatTime(beginsOn),
          endTime: formatTime(endsOn),
        })
      }}</span>
    </p>
    <p v-else-if="showStartTime && !showEndTime">
      {{
        t("On {date} starting at {startTime}", {
          date: formatDate(beginsOn),
          startTime: formatTime(beginsOn),
        })
      }}
    </p>
    <p v-else-if="!showStartTime && showEndTime">
      {{
        t("On {date} ending at {endTime}", {
          date: formatDate(beginsOn),
          endTime: formatTime(endsOn),
        })
      }}
    </p>
    <p v-else>
      {{ t("On {date}", { date: formatDate(beginsOn) }) }}
    </p>
  </template>
  <!-- endsOn is set and !isSameDay() -->
  <p v-else-if="showStartTime && showEndTime">
    <span>
      {{
        t("From the {startDate} at {startTime} to the {endDate} at {endTime}", {
          startDate: formatDate(beginsOn),
          startTime: formatTime(beginsOn),
          endDate: formatDate(endsOn),
          endTime: formatTime(endsOn),
        })
      }}
    </span>
  </p>
  <p v-else-if="showStartTime && !showEndTime">
    <span>
      {{
        t("From the {startDate} at {startTime} to the {endDate}", {
          startDate: formatDate(beginsOn),
          startTime: formatTime(beginsOn),
          endDate: formatDate(endsOn),
        })
      }}
    </span>
  </p>
  <p v-else-if="!showStartTime && showEndTime">
    <span>
      {{
        t("From the {startDate} to the {endDate} at {endTime}", {
          startDate: formatDate(beginsOn),
          endDate: formatDate(endsOn),
          endTime: formatTime(endsOn),
        })
      }}
    </span>
  </p>
  <p v-else>
    {{
      t("From the {startDate} to the {endDate}", {
        startDate: formatDate(beginsOn),
        endDate: formatDate(endsOn),
      })
    }}
  </p>
  <o-switch
    size="small"
    v-model="showLocalTimezone"
    v-if="differentFromUserTimezone"
  >
    {{ singleTimeZone }}
  </o-switch>
</template>
<script lang="ts" setup>
import {
  formatDateString,
  formatDateTimeString,
  formatTimeString,
} from "@/filters/datetime";
import { getTimezoneOffset } from "date-fns-tz";
import { computed, ref } from "vue";
import { useI18n } from "vue-i18n";

const props = withDefaults(
  defineProps<{
    beginsOn: string;
    endsOn?: string;
    showStartTime?: boolean;
    showEndTime?: boolean;
    timezone?: string;
    userTimezone?: string;
  }>(),
  {
    showStartTime: true,
    showEndTime: true,
  }
);

const { t } = useI18n({ useScope: "global" });

const showLocalTimezone = ref(true);

const timezoneToShow = computed((): string | undefined => {
  if (showLocalTimezone.value) {
    return props.timezone ?? userActualTimezone.value;
  }
  return userActualTimezone.value;
});

const userActualTimezone = computed((): string => {
  if (props.userTimezone) {
    return props.userTimezone;
  }
  return Intl.DateTimeFormat().resolvedOptions().timeZone;
});

const formatDate = (value: string): string | undefined => {
  return formatDateString(value, timezoneToShow.value ?? "Etc/UTC");
};

const formatTime = (value: string): string | undefined => {
  return formatTimeString(value, timezoneToShow.value ?? "Etc/UTC");
};

// We need to compare date after the offset is applied
// Because some date can be in the same day in a time zone, but different day in another.
// Example : From 2025-11-30 at 23:00 to 2025-12-01 01:00 in Asia/Shanghai (different days)
//           It is from 2025-11-30 at 16:00 to 2025-11-30 at 18:00 in Europe/Paris (same day)
const isSameDay = (): boolean => {
  if (!props.endsOn) return false;

  const offset =
    getTimezoneOffset(timezoneToShow.value ?? "Etc/UTC", new Date()) /
    (60 * 1000);

  const beginsOnOffset = new Date(props.beginsOn);
  beginsOnOffset.setUTCMinutes(beginsOnOffset.getUTCMinutes() + offset);

  const endsOnOffset = new Date(props.endsOn);
  endsOnOffset.setUTCMinutes(endsOnOffset.getUTCMinutes() + offset);

  return (
    beginsOnOffset.getUTCFullYear() === endsOnOffset.getUTCFullYear() &&
    beginsOnOffset.getUTCMonth() === endsOnOffset.getUTCMonth() &&
    beginsOnOffset.getUTCDate() === endsOnOffset.getUTCDate()
  );
};

const differentFromUserTimezone = computed((): boolean => {
  return (
    !!props.timezone &&
    !!userActualTimezone.value &&
    getTimezoneOffset(props.timezone, new Date()) !==
      getTimezoneOffset(userActualTimezone.value, new Date()) &&
    props.timezone !== userActualTimezone.value
  );
});

const singleTimeZone = computed((): string => {
  if (showLocalTimezone.value) {
    return t("Local time ({timezone})", {
      timezone: timezoneToShow.value,
    });
  }
  return t("Time in your timezone ({timezone})", {
    timezone: timezoneToShow.value,
  });
});
</script>
