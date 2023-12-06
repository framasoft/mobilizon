export function nl2br(text: string): string {
  return text.replace(/(?:\r\n|\r|\n)/g, "<br>");
}

export const getValueFromMeta = (name: string): string | null => {
  const element = document.querySelector(`meta[name="${name}"]`);
  if (element && element.getAttribute("content")) {
    return element.getAttribute("content");
  }
  return null;
};
