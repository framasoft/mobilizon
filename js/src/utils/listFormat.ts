const shortConjunctionFormatter = new Intl.ListFormat(undefined, {
  style: "short",
  type: "conjunction",
});

const shortDisjunctionFormatter = new Intl.ListFormat(undefined, {
  style: "short",
  type: "disjunction",
});

export const listShortConjunctionFormatter = (list: Array<string>): string => {
  return shortConjunctionFormatter.format(list);
};

export const listShortDisjunctionFormatter = (list: Array<string>): string => {
  return shortDisjunctionFormatter.format(list);
};
