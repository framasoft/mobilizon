import { i18n } from "../utils/i18n";

function parseDateTime(value: string): Date {
  return new Date(value);
}

function formatDateISOStringWithoutTime(value: string): string {
  return parseDateTime(value).toISOString().split("T")[0];
}

function formatDateString(value: string, timeZone?: string): string {
  return parseDateTime(value).toLocaleString(locale(), {
    weekday: "long",
    year: "numeric",
    month: "long",
    day: "numeric",
    timeZone: timeZone,
  });
}

function formatTimeString(value: string, timeZone?: string): string {
  return parseDateTime(value).toLocaleTimeString(locale(), {
    hour: "numeric",
    minute: "numeric",
    timeZone: timeZone,
  });
}

// TODO: These can be removed in favor of dateStyle/timeStyle when those two have sufficient support
// https://caniuse.com/mdn-javascript_builtins_intl_datetimeformat_datetimeformat_datestyle
const LONG_DATE_FORMAT_OPTIONS: any = {
  weekday: undefined,
  year: "numeric",
  month: "long",
  day: "numeric",
  hour: undefined,
  minute: undefined,
};

const LONG_TIME_FORMAT_OPTIONS: any = {
  weekday: "long",
  hour: "numeric",
  minute: "numeric",
};

const SHORT_DATE_FORMAT_OPTIONS: any = {
  weekday: undefined,
  year: "numeric",
  month: "short",
  day: "numeric",
  hour: undefined,
  minute: undefined,
};

const SHORT_TIME_FORMAT_OPTIONS: any = {
  weekday: "short",
  hour: "numeric",
  minute: "numeric",
};

function formatDateTimeString(
  value: string,
  timeZone: string | null | undefined = undefined,
  showTime = true,
  dateFormat = "long"
): string {
  const isLongFormat = dateFormat === "long";
  let options = isLongFormat
    ? LONG_DATE_FORMAT_OPTIONS
    : SHORT_DATE_FORMAT_OPTIONS;
  if (showTime) {
    options = {
      ...options,
      ...(isLongFormat ? LONG_TIME_FORMAT_OPTIONS : SHORT_TIME_FORMAT_OPTIONS),
      timeZone: timeZone || undefined,
    };
  }
  const format = new Intl.DateTimeFormat(locale(), options);
  return format.format(parseDateTime(value));
}

const locale = () => i18n.global.locale.replace("_", "-");

export {
  formatDateISOStringWithoutTime,
  formatDateString,
  formatTimeString,
  formatDateTimeString,
};
