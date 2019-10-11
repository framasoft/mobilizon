function localeMonthNames(): string[] {
  const monthNames: string[] = [];
  for (let i = 0; i < 12; i += 1) {
    const d = new Date(2019, i, 1);
    const month = d.toLocaleString('default', { month: 'long' });
    monthNames.push(month);
  }
  return monthNames;
}

function localeShortWeekDayNames(): string[] {
  const weekDayNames: string[] = [];
  for (let i = 13; i < 20; i += 1) {
    const d = new Date(2019, 9, i);
    const weekDay = d.toLocaleString('default', { weekday: 'short' });
    weekDayNames.push(weekDay);
  }
  return weekDayNames;
}

export { localeMonthNames, localeShortWeekDayNames };
