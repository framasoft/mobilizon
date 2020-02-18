export interface IPOIIcon {
  icon: string;
  color?: string;
}

interface IPOIIcons {
  [key: string]: IPOIIcon;
}

export const poiIcons: IPOIIcons = {
  default: {
    icon: "map-marker",
    color: "#5C6F84",
  },
  defaultAdministrative: {
    icon: "city",
    color: "#5c6f84",
  },
  defaultStreet: {
    icon: "road-variant",
    color: "#5c6f84",
  },
  defaultAddress: {
    icon: "home",
    color: "#5c6f84",
  },
  place_house: {
    icon: "home",
    color: "#5c6f84",
  },
  theatre: {
    icon: "drama-masks",
  },
  parking: {
    icon: "parking",
  },
  police: {
    icon: "police-badge",
  },
  post_office: {
    icon: "email",
  },
  university: {
    icon: "school",
  },
  college: {
    icon: "school",
  },
  park: {
    icon: "pine-tree",
  },
  garden: {
    icon: "pine-tree",
  },
  bicycle_rental: {
    icon: "bicycle",
  },
  hospital: {
    icon: "hospital-box",
  },
  townhall: {
    icon: "office-building",
  },
  toilets: {
    icon: "human-male-female",
  },
  hairdresser: {
    icon: "content-cut",
  },
};
