export type CategoryPictureLicencingElement = { name: string; url: string };
export type CategoryPictureLicencing = {
  author: CategoryPictureLicencingElement;
  source: CategoryPictureLicencingElement;
  license?: CategoryPictureLicencingElement;
};

export const categoriesPicturesLicences: Record<
  string,
  CategoryPictureLicencing
> = {
  THEATRE: {
    author: {
      name: "David Joyce",
      url: "https://www.flickr.com/photos/deapeajay/",
    },
    source: {
      name: "Flickr",
      url: "https://www.flickr.com/photos/30815420@N00/2213310171",
    },
    license: {
      name: "CC BY-SA",
      url: "https://creativecommons.org/licenses/by-sa/2.0/",
    },
  },
  SPORTS: {
    author: {
      name: "Md Mahdi",
      url: "https://unsplash.com/@mahdi17",
    },
    source: {
      name: "Unsplash",
      url: "https://unsplash.com/photos/lQpFRPrepQ8",
    },
  },
  MUSIC: {
    author: {
      name: "Michael Starkie",
      url: "https://unsplash.com/@starkie_pics",
    },
    source: {
      name: "Unsplash",
      url: "https://unsplash.com/photos/YjtevpXFHQY",
    },
  },
  ARTS: {
    author: {
      name: "RhondaK Native Florida Folk Artist",
      url: "https://unsplash.com/@rhondak",
    },
    source: {
      name: "Unsplash",
      url: "https://unsplash.com/photos/_Yc7OtfFn-0",
    },
  },
  SPIRITUALITY_RELIGION_BELIEFS: {
    author: {
      name: "The Dancing Rain",
      url: "https://unsplash.com/@thedancingrain",
    },
    source: {
      name: "Unsplash",
      url: "https://unsplash.com/photos/_KPuV9qSSlU",
    },
  },
  MOVEMENTS_POLITICS: {
    author: {
      name: "Kyle Fiori",
      url: "https://unsplash.com/@navy99",
    },
    source: {
      name: "Unsplash",
      url: "https://unsplash.com/photos/moytQ7vzhAM",
    },
  },
  PARTY: {
    author: {
      name: "Amy Shamblen",
      url: "https://unsplash.com/@amyshamblen",
    },
    source: {
      name: "Unsplash",
      url: "https://unsplash.com/photos/pJ_DCj9KswI",
    },
  },
  BUSINESS: {
    author: {
      name: "Simone Hutsch",
      url: "https://unsplash.com/@heysupersimi",
    },
    source: {
      name: "Unsplash",
      url: "https://unsplash.com/photos/6-c8GV2MBmg",
    },
  },
  FILM_MEDIA: {
    author: {
      name: "Dan Senior",
      url: "https://unsplash.com/@dansenior",
    },
    source: {
      name: "Unsplash",
      url: "https://unsplash.com/photos/ENtn4fH8C3g",
    },
  },
  PHOTOGRAPHY: {
    author: {
      name: "Nathyn Masters",
      url: "https://unsplash.com/@nathynmasters",
    },
    source: {
      name: "Unsplash",
      url: "https://unsplash.com/photos/k3oSs0hWOPo",
    },
  },
  HEALTH: {
    author: {
      name: "Derek Finch",
      url: "https://unsplash.com/@drugwatcher",
    },
    source: {
      name: "Unsplash",
      url: "https://unsplash.com/photos/Gi8Q8IfpxdY",
    },
  },
  GAMES: {
    author: {
      name: "Randy Fath",
      url: "https://unsplash.com/@randyfath",
    },
    source: {
      name: "Unsplash",
      url: "https://unsplash.com/photos/_EoxKxrDL20",
    },
  },
  OUTDOORS_ADVENTURE: {
    author: {
      name: "Davide Sacchet",
      url: "https://unsplash.com/@davide_sak_",
    },
    source: {
      name: "Unsplash",
      url: "https://unsplash.com/photos/RYN-kov1lTY",
    },
  },
  FOOD_DRINK: {
    author: {
      name: "sina piryae",
      url: "https://unsplash.com/@sinapiryae",
    },
    source: {
      name: "Unsplash",
      url: "https://unsplash.com/photos/bBzjWthTqb8",
    },
  },
  CRAFTS: {
    author: {
      name: "rocknwool",
      url: "https://unsplash.com/@rocknwool",
    },
    source: {
      name: "Unsplash",
      url: "https://unsplash.com/photos/Jcb5O26G08A",
    },
  },
  LGBTQ: {
    author: {
      name: "analuisa gamboa",
      url: "https://unsplash.com/@anigmb",
    },
    source: {
      name: "Unsplash",
      url: "https://unsplash.com/photos/HsraPtCtRCM",
    },
  },
};

export const categoriesWithPictures = [
  "SPORTS",
  "THEATRE",
  "MUSIC",
  "ARTS",
  "MOVEMENTS_POLITICS",
  "SPIRITUALITY_RELIGION_BELIEFS",
  "PARTY",
  "BUSINESS",
  "FILM_MEDIA",
  "PHOTOGRAPHY",
  "HEALTH",
  "GAMES",
  "OUTDOORS_ADVENTURE",
  "FOOD_DRINK",
  "CRAFTS",
  "LGBTQ",
];
