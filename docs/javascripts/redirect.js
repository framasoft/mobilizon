const languages = ["fr"];

const navigatorLanguage =
  window.navigator.userLanguage || window.navigator.language;

let language;
if (languages.includes(navigatorLanguage)) {
  language = navigatorLanguage;
}
const split = navigatorLanguage.split("-")[0];
if (languages.includes(split)) {
  language = split;
}
const url = new URL(window.location.href);
if (language && (url.pathname === "/" || url.pathname.startsWith("/use/"))) {
  url.pathname = `/${language}${url.pathname}`;
  window.location.replace(url);
}
