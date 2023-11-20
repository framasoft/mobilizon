declare namespace Intl {
  type Locale = string;
  type Locales = Locale[];
  type Type = "conjunction" | "disjunction" | "unit";
  type Style = "long" | "short" | "narrow";
  type LocaleMatcher = "lookup" | "best fit";
  interface ListFormatOptions {
    type: Type;
    style: Style;
    localeMatcher: LocaleMatcher;
  }

  class ListFormat {
    constructor(
      locales?: Locale | Locales | undefined,
      options?: Partial<ListFormatOptions>
    );
    public format: (items: string[]) => string;
  }
}
