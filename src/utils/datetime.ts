import type { Locale } from "date-fns";
import { format } from "date-fns";

function localeMonthNames(): string[] {
  const monthNames: string[] = [];
  for (let i = 0; i < 12; i += 1) {
    const d = new Date(2019, i, 1);
    const month = d.toLocaleString("default", { month: "long" });
    monthNames.push(month);
  }
  return monthNames;
}

function localeShortWeekDayNames(): string[] {
  const weekDayNames: string[] = [];
  for (let i = 13; i < 20; i += 1) {
    const d = new Date(2019, 9, i);
    const weekDay = d.toLocaleString("default", { weekday: "short" });
    weekDayNames.push(weekDay);
  }
  return weekDayNames;
}

// https://stackoverflow.com/a/18650828/10204399
function formatBytes(
  bytes: number,
  decimals = 2,
  locale: string | undefined = undefined
): string {
  const formatNumber = (value = 0, unit = "byte") =>
    new Intl.NumberFormat(locale, {
      style: "unit",
      unit,
      unitDisplay: "long",
    }).format(value);

  if (bytes === 0) return formatNumber(0);
  if (bytes < 0 || bytes > Number.MAX_SAFE_INTEGER) {
    throw new RangeError(
      "Number mustn't be negative and be inferior to Number.MAX_SAFE_INTEGER"
    );
  }

  const k = 1024;
  const dm = decimals < 0 ? 0 : decimals;
  const sizes = [
    "byte",
    "kilobyte",
    "megabyte",
    "gigabyte",
    "terabyte",
    "petabyte",
  ];

  const i = Math.floor(Math.log(bytes) / Math.log(k));

  return formatNumber(parseFloat((bytes / k ** i).toFixed(dm)), sizes[i]);
}

function roundToNearestMinute(date = new Date()) {
  const minutes = 1;
  const ms = 1000 * 60 * minutes;

  // 👇️ replace Math.round with Math.ceil to always round UP
  return new Date(Math.round(date.getTime() / ms) * ms);
}

function formatDateTimeForEvent(dateTime: Date, locale: Locale): string {
  return format(dateTime, "PPp", { locale });
}

export {
  localeMonthNames,
  localeShortWeekDayNames,
  formatBytes,
  roundToNearestMinute,
  formatDateTimeForEvent,
};
