const shortConjunctionFormatter = new Intl.ListFormat(undefined, {
  style: "short",
  type: "conjunction",
});

const shortDisjunctionFormatter = new Intl.ListFormat(undefined, {
  style: "short",
  type: "disjunction",
});

const listFormatAvailable = typeof Intl?.ListFormat === "function";

export const listShortConjunctionFormatter = (list: Array<string>): string => {
  return listFormatAvailable
    ? shortConjunctionFormatter.format(list)
    : list.join(",");
};

export const listShortDisjunctionFormatter = (list: Array<string>): string => {
  return listFormatAvailable
    ? shortDisjunctionFormatter.format(list)
    : list.join(",");
};
