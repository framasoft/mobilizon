function parseDateTime(value: string): Date {
  return new Date(value);
}

function formatDateString(value: string): string {
  return parseDateTime(value).toLocaleString(undefined, { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' });
}

function formatTimeString(value: string): string {
  return parseDateTime(value).toLocaleTimeString(undefined, { hour: 'numeric', minute: 'numeric' });
}

function formatDateTimeString(value: string): string {
  return parseDateTime(value).toLocaleTimeString(undefined, { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric', hour: 'numeric', minute: 'numeric' });
}



export { formatDateString, formatTimeString, formatDateTimeString };
