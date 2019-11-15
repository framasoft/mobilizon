/**
 * New Line to <br>
 *
 * @param {string} str Input text
 * @return {string} Filtered text
 */
export function nl2br(str: String): String {
  return `${str}`.replace(/([^>\r\n]?)(\r\n|\n\r|\r|\n)/g, '$1<br>');
}
