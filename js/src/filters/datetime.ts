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
  return parseDateTime(value).toLocaleTimeString(undefined, { hour: "numeric", minute: "numeric" });
}

function formatDateTimeString(value: string, showTime = true): string {
  const options = {
    weekday: "long",
    year: "numeric",
    month: "long",
    day: "numeric",
    hour: "numeric",
    minute: "numeric",
  };
  if (showTime) {
    options.hour = "numeric";
    options.minute = "numeric";
  }
  return parseDateTime(value).toLocaleTimeString(undefined, options);
}

export { formatDateString, formatTimeString, formatDateTimeString };
