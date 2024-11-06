<template>
  <p v-if="!endsOn">
    <span>{{
      formatDateTimeString(beginsOn, timezoneToShow, showStartTime)
    }}</span>
    <br />
    <o-switch
      size="small"
      v-model="showLocalTimezone"
      v-if="differentFromUserTimezone"
    >
      {{ singleTimeZone }}
    </o-switch>
  </p>
  <!-- endsOn is set and isSameDay() -->
  <template v-else-if="isSameDay()">
    <p v-if="showStartTime && showEndTime">
      <span>{{
        t("On {date} from {startTime} to {endTime}", {
          date: formatDate(beginsOn),
          startTime: formatTime(beginsOn, timezoneToShow),
          endTime: formatTime(endsOn, timezoneToShow),
        })
      }}</span>
      <br />
      <o-switch
        size="small"
        v-model="showLocalTimezone"
        v-if="differentFromUserTimezone"
      >
        {{ singleTimeZone }}
      </o-switch>
    </p>
    <p v-else-if="showStartTime && !showEndTime">
      {{
        t("On {date} starting at {startTime}", {
          date: formatDate(beginsOn),
          startTime: formatTime(beginsOn, timezoneToShow),
        })
      }}
    </p>
    <p v-else-if="!showStartTime && showEndTime">
      {{
        t("On {date} ending at {endTime}", {
          date: formatDate(beginsOn),
          endTime: formatTime(endsOn, timezoneToShow),
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
          startTime: formatTime(beginsOn, timezoneToShow),
          endDate: formatDate(endsOn),
          endTime: formatTime(endsOn, timezoneToShow),
        })
      }}
    </span>
    <br />
    <o-switch
      size="small"
      v-model="showLocalTimezone"
      v-if="differentFromUserTimezone"
    >
      {{ multipleTimeZones }}
    </o-switch>
  </p>
  <p v-else-if="showStartTime && !showEndTime">
    <span>
      {{
        t("From the {startDate} at {startTime} to the {endDate}", {
          startDate: formatDate(beginsOn),
          startTime: formatTime(beginsOn, timezoneToShow),
          endDate: formatDate(endsOn),
        })
      }}
    </span>
    <br />
    <o-switch
      size="small"
      v-model="showLocalTimezone"
      v-if="differentFromUserTimezone"
    >
      {{ singleTimeZone }}
    </o-switch>
  </p>
  <p v-else-if="!showStartTime && showEndTime">
    <span>
      {{
        t("From the {startDate} to the {endDate} at {endTime}", {
          startDate: formatDate(beginsOn),
          endDate: formatDate(endsOn),
          endTime: formatTime(endsOn, timezoneToShow),
        })
      }}
    </span>
    <br />
    <o-switch
      size="small"
      v-model="showLocalTimezone"
      v-if="differentFromUserTimezone"
    >
      {{ singleTimeZone }}
    </o-switch>
  </p>
  <p v-else>
    {{
      t("From the {startDate} to the {endDate}", {
        startDate: formatDate(beginsOn),
        endDate: formatDate(endsOn),
      })
    }}
  </p>
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
    return props.timezone;
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
  return formatDateString(value);
};

const formatTime = (
  value: string,
  timezone: string | undefined = undefined
): string | undefined => {
  return formatTimeString(value, timezone ?? "Etc/UTC");
};

const isSameDay = (): boolean => {
  if (!props.endsOn) return false;
  return (
    beginsOnDate.value.toDateString() === new Date(props.endsOn).toDateString()
  );
};

const beginsOnDate = computed((): Date => {
  return new Date(props.beginsOn);
});

const differentFromUserTimezone = computed((): boolean => {
  return (
    !!props.timezone &&
    !!userActualTimezone.value &&
    getTimezoneOffset(props.timezone, beginsOnDate.value) !==
      getTimezoneOffset(userActualTimezone.value, beginsOnDate.value) &&
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

const multipleTimeZones = computed((): string => {
  if (showLocalTimezone.value) {
    return t("Local times ({timezone})", {
      timezone: timezoneToShow.value,
    });
  }
  return t("Times in your timezone ({timezone})", {
    timezone: timezoneToShow.value,
  });
});
</script>
