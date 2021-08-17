import {
  EventMetadataType,
  EventMetadataKeyType,
  EventMetadataCategories,
} from "@/types/enums";
import { IEventMetadataDescription } from "@/types/event-metadata";
import { i18n } from "@/utils/i18n";

export const eventMetaDataList: IEventMetadataDescription[] = [
  {
    icon: "wheelchair-accessibility",
    key: "mz:accessibility:wheelchairAccessible",
    label: i18n.t("Wheelchair accessibility") as string,
    description: i18n.t(
      "Whether the event is accessible with a wheelchair"
    ) as string,
    value: "",
    type: EventMetadataType.STRING,
    keyType: EventMetadataKeyType.CHOICE,
    choices: {
      no: i18n.t("Not accessible with a wheelchair") as string,
      partially: i18n.t("Partially accessible with a wheelchair") as string,
      fully: i18n.t("Fully accessible with a wheelchair") as string,
    },
    category: EventMetadataCategories.ACCESSIBILITY,
  },
  {
    icon: "subtitles",
    key: "mz:accessibility:live:subtitle",
    label: i18n.t("Subtitles") as string,
    description: i18n.t("Whether the event live video is subtitled") as string,
    value: "",
    type: EventMetadataType.BOOLEAN,
    keyType: EventMetadataKeyType.PLAIN,
    choices: {
      true: i18n.t("The event live video contains subtitles") as string,
      false: i18n.t(
        "The event live video does not contain subtitles"
      ) as string,
    },
    category: EventMetadataCategories.ACCESSIBILITY,
  },
  {
    icon: "mz:icon:sign_language",
    key: "mz:accessibility:live:sign_language",
    label: i18n.t("Sign Language") as string,
    description: i18n.t(
      "Whether the event is interpreted in sign language"
    ) as string,
    value: "",
    type: EventMetadataType.BOOLEAN,
    keyType: EventMetadataKeyType.PLAIN,
    choices: {
      true: i18n.t("The event has a sign language interpreter") as string,
      false: i18n.t(
        "The event hasn't got a sign language interpreter"
      ) as string,
    },
    category: EventMetadataCategories.ACCESSIBILITY,
  },
  {
    icon: "youtube",
    key: "mz:replay:youtube:url",
    label: i18n.t("YouTube replay") as string,
    description: i18n.t(
      "The URL where the event live can be watched again after it has ended"
    ) as string,
    value: "",
    type: EventMetadataType.STRING,
    keyType: EventMetadataKeyType.URL,
    pattern:
      /http(?:s?):\/\/(?:www\.)?youtu(?:be\.com\/watch\?v=|\.be\/)([\w\-_]*)(&(amp;)?‌[\w?‌=]*)?/,
    category: EventMetadataCategories.REPLAY,
  },
  // {
  //   icon: "twitch",
  //   key: "mz:replay:twitch:url",
  //   label: i18n.t("Twitch replay") as string,
  //   description: i18n.t(
  //     "The URL where the event live can be watched again after it has ended"
  //   ) as string,
  //   value: "",
  //   type: EventMetadataType.STRING,
  // },
  {
    icon: "mz:icon:peertube",
    key: "mz:replay:peertube:url",
    label: i18n.t("PeerTube replay") as string,
    description: i18n.t(
      "The URL where the event live can be watched again after it has ended"
    ) as string,
    value: "",
    type: EventMetadataType.STRING,
    keyType: EventMetadataKeyType.URL,
    pattern: /^https?:\/\/([^/]+)\/(?:videos\/(?:watch|embed)|w)\/([^/]+)$/,
    category: EventMetadataCategories.REPLAY,
  },
  {
    icon: "mz:icon:peertube",
    key: "mz:live:peertube:url",
    label: i18n.t("PeerTube live") as string,
    description: i18n.t(
      "The URL where the event can be watched live"
    ) as string,
    value: "",
    type: EventMetadataType.STRING,
    keyType: EventMetadataKeyType.URL,
    pattern: /^https?:\/\/([^/]+)\/(?:videos\/(?:watch|embed)|w)\/([^/]+)$/,
    category: EventMetadataCategories.LIVE,
  },
  {
    icon: "twitch",
    key: "mz:live:twitch:url",
    label: i18n.t("Twitch live") as string,
    description: i18n.t(
      "The URL where the event can be watched live"
    ) as string,
    value: "",
    type: EventMetadataType.STRING,
    keyType: EventMetadataKeyType.URL,
    placeholder: "https://www.twitch.tv/",
    pattern: /^(?:https?:\/\/)?(?:www\.|go\.)?twitch\.tv\/([a-z0-9_]+)($|\?)/,
    category: EventMetadataCategories.LIVE,
  },
  {
    icon: "youtube",
    key: "mz:live:youtube:url",
    label: i18n.t("YouTube live") as string,
    description: i18n.t(
      "The URL where the event can be watched live"
    ) as string,
    value: "",
    type: EventMetadataType.STRING,
    keyType: EventMetadataKeyType.URL,
    pattern:
      /http(?:s?):\/\/(?:www\.)?youtu(?:be\.com\/watch\?v=|\.be\/)([\w\-_]*)(&(amp;)?‌[\w?‌=]*)?/,
    category: EventMetadataCategories.LIVE,
  },
  {
    icon: "calendar-check",
    key: "mz:poll:framadate:url",
    label: i18n.t("Framadate poll") as string,
    description: i18n.t(
      "The URL of a poll where the choice for the event date is happening"
    ) as string,
    value: "",
    placeholder: "https://framadate.org/",
    type: EventMetadataType.STRING,
    keyType: EventMetadataKeyType.URL,
    category: EventMetadataCategories.TOOLS,
  },
  {
    icon: "file-document-edit",
    key: "mz:notes:etherpad:url",
    label: i18n.t("Etherpad notes") as string,
    description: i18n.t(
      "The URL of a pad where notes are being taken collaboratively"
    ) as string,
    value: "",
    placeholder: i18n.t(
      "https://mensuel.framapad.org/p/some-secret-token"
    ) as string,
    type: EventMetadataType.STRING,
    keyType: EventMetadataKeyType.URL,
    category: EventMetadataCategories.TOOLS,
  },
  {
    icon: "twitter",
    key: "mz:social:twitter:account",
    label: i18n.t("Twitter account") as string,
    description: i18n.t(
      "A twitter account handle to follow for event updates"
    ) as string,
    value: "",
    placeholder: "@JoinMobilizon",
    type: EventMetadataType.STRING,
    keyType: EventMetadataKeyType.HANDLE,
    category: EventMetadataCategories.SOCIAL,
  },
  {
    icon: "mz:icon:fediverse",
    key: "mz:social:fediverse:account_url",
    label: i18n.t("Fediverse account") as string,
    description: i18n.t(
      "A fediverse account URL to follow for event updates"
    ) as string,
    value: "",
    placeholder: "https://framapiaf.org/@mobilizon",
    type: EventMetadataType.STRING,
    keyType: EventMetadataKeyType.URL,
    category: EventMetadataCategories.SOCIAL,
  },
  {
    icon: "ticket-confirmation",
    key: "mz:ticket:external_url",
    label: i18n.t("Online ticketing") as string,
    description: i18n.t("An URL to an external ticketing platform") as string,
    value: "",
    type: EventMetadataType.STRING,
    keyType: EventMetadataKeyType.URL,
    category: EventMetadataCategories.BOOKING,
  },
  {
    icon: "cash",
    key: "mz:ticket:price_url",
    label: i18n.t("Price sheet") as string,
    description: i18n.t(
      "A link to a page presenting the price options"
    ) as string,
    value: "",
    type: EventMetadataType.STRING,
    keyType: EventMetadataKeyType.URL,
    category: EventMetadataCategories.DETAILS,
  },
  {
    icon: "calendar-text",
    key: "mz:schedule_url",
    label: i18n.t("Schedule") as string,
    description: i18n.t(
      "A link to a page presenting the event schedule"
    ) as string,
    value: "",
    type: EventMetadataType.STRING,
    keyType: EventMetadataKeyType.URL,
    category: EventMetadataCategories.DETAILS,
  },
  {
    icon: "webcam",
    key: "mz:visio:jitsi_meet",
    label: i18n.t("Jisti Meet") as string,
    description: i18n.t("The Jitsi Meet video teleconference URL") as string,
    value: "",
    type: EventMetadataType.STRING,
    keyType: EventMetadataKeyType.URL,
    category: EventMetadataCategories.VIDEO_CONFERENCE,
    placeholder: "https://meet.jit.si/AFewWords",
  },
  {
    icon: "webcam",
    key: "mz:visio:zoom",
    label: i18n.t("Zoom") as string,
    description: i18n.t("The Zoom video teleconference URL") as string,
    value: "",
    type: EventMetadataType.STRING,
    keyType: EventMetadataKeyType.URL,
    category: EventMetadataCategories.VIDEO_CONFERENCE,
    pattern: /https:\/\/.*\.?zoom.us\/.*/,
  },
  {
    icon: "microsoft-teams",
    key: "mz:visio:microsoft_teams",
    label: i18n.t("Microsoft Teams") as string,
    description: i18n.t(
      "The Microsoft Teams video teleconference URL"
    ) as string,
    value: "",
    type: EventMetadataType.STRING,
    keyType: EventMetadataKeyType.URL,
    category: EventMetadataCategories.VIDEO_CONFERENCE,
    pattern: /https:\/\/teams\.live\.com\/meet\/.+/,
  },
  {
    icon: "google-hangouts",
    key: "mz:visio:google_meet",
    label: i18n.t("Google Meet") as string,
    description: i18n.t("The Google Meet video teleconference URL") as string,
    value: "",
    type: EventMetadataType.STRING,
    keyType: EventMetadataKeyType.URL,
    category: EventMetadataCategories.VIDEO_CONFERENCE,
    pattern: /https:\/\/meet\.google\.com\/.+/,
  },
  {
    icon: "webcam",
    key: "mz:visio:big_blue_button",
    label: i18n.t("Big Blue Button") as string,
    description: i18n.t(
      "The Big Blue Button video teleconference URL"
    ) as string,
    value: "",
    type: EventMetadataType.STRING,
    keyType: EventMetadataKeyType.URL,
    category: EventMetadataCategories.VIDEO_CONFERENCE,
  },
];
