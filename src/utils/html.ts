export const getValueFromMeta = (name: string): string | null => {
  const element = document.querySelector(`meta[name="${name}"]`);
  if (element && element.getAttribute("content")) {
    return element.getAttribute("content");
  }
  return null;
};

export function escapeHtml(html: string) {
  const p = document.createElement("p");
  p.appendChild(document.createTextNode(html.trim()));

  const escapedContent = p.innerHTML;
  p.remove();

  return escapedContent;
}
