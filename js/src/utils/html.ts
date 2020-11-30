export function nl2br(text: string): string {
  return text.replace(/(?:\r\n|\r|\n)/g, "<br>");
}
