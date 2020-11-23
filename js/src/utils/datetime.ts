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
function formatBytes(bytes: number, decimals = 2): string {
  if (bytes === 0) return "0 Bytes";

  const k = 1024;
  const dm = decimals < 0 ? 0 : decimals;
  const sizes = ["Bytes", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];

  const i = Math.floor(Math.log(bytes) / Math.log(k));

  return `${parseFloat((bytes / k ** i).toFixed(dm))} ${sizes[i]}`;
}

export { localeMonthNames, localeShortWeekDayNames, formatBytes };
