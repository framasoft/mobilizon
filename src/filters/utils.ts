/**
 * New Line to <br>
 *
 * @param {string} str Input text
 * @return {string} Filtered text
 */
export default function nl2br(str: string): string {
  return `${str}`.replace(/([^>\r\n]?)(\r\n|\n\r|\r|\n)/g, "$1<br>");
}
