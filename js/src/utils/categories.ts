import { i18n } from "@/utils/i18n";

export const eventCategories = [
  {
    id: "ARTS",
    label: i18n.t("Arts"),
    icon: "palette",
  },
  {
    id: "BOOK_CLUBS",
    label: i18n.t("Book Clubs"),
    icon: "favourite-book",
  },
  {
    id: "BUSINESS",
    label: i18n.t("Business"),
  },
  {
    id: "CAUSES",
    label: i18n.t("Causes"),
  },
  {
    id: "COMEDY",
    label: i18n.t("Comedy"),
  },
  {
    id: "CRAFTS",
    label: i18n.t("Crafts"),
  },
  {
    id: "FOOD_DRINK",
    label: i18n.t("Food & Drink"),
  },
  {
    id: "HEALTH",
    label: i18n.t("Health"),
  },
  {
    id: "MUSIC",
    label: i18n.t("Music"),
  },
  {
    id: "AUTO_BOAT_AIR",
    label: i18n.t("Auto, Boat & Air"),
  },
  {
    id: "COMMUNITY",
    label: i18n.t("Community"),
  },
  {
    id: "FAMILY_EDUCATION",
    label: i18n.t("Family & Education"),
  },
  {
    id: "FASHION_BEAUTY",
    label: i18n.t("Fashion & Beauty"),
  },
  {
    id: "FILM_MEDIA",
    label: i18n.t("Film & Media"),
  },
  {
    id: "GAMES",
    label: i18n.t("Games"),
  },
  // eslint-disable-next-line @typescript-eslint/ban-ts-comment
  // @ts-ignore
].sort(({ label: label1 }, { label: label2 }) => label1.localeCompare(label2));
