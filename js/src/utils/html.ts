export function nl2br(text: string): string {
  return text.replace(/(?:\r\n|\r|\n)/g, "<br>");
}

export function htmlToText(html: string) {
  const template = document.createElement("template");
  const trimmedHTML = html.trim();
  template.innerHTML = trimmedHTML;
  const text = template.content.textContent;
  template.remove();
  return text;
}
