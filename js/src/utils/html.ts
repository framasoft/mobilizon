export function nl2br(text: string): string {
  return text.replace(/(?:\r\n|\r|\n)/g, "<br>");
}

export function flattenHTMLParagraphs(html: string): string {
  return html.replace("</p><p>", "<br />").replace(/<?\/p>/g, "");
}
