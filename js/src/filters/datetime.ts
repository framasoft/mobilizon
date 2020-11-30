import { DateTimeFormatOptions } from "vue-i18n";

function parseDateTime(value: string): Date {
  return new Date(value);
}

function formatDateString(value: string): string {
  return parseDateTime(value).toLocaleString(undefined, {
    weekday: "long",
    year: "numeric",
    month: "long",
    day: "numeric",
  });
}

function formatTimeString(value: string): string {
  return parseDateTime(value).toLocaleTimeString(undefined, {
    hour: "numeric",
    minute: "numeric",
  });
}

function formatDateTimeString(value: string, showTime = true): string {
  const options: DateTimeFormatOptions = {
    weekday: undefined,
    year: "numeric",
    month: "long",
    day: "numeric",
    hour: undefined,
    minute: undefined,
  };
  if (showTime) {
    options.weekday = "long";
    options.hour = "numeric";
    options.minute = "numeric";
  }
  const format = new Intl.DateTimeFormat(undefined, options);
  return format.format(parseDateTime(value));
}

export { formatDateString, formatTimeString, formatDateTimeString };
