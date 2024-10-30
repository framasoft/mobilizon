<template>
  <component
    :is="componentInstance"
    v-if="componentInstance"
    :size="realSize"
  />
</template>
<script lang="ts" setup>
import { computed, defineAsyncComponent } from "vue";

const icons: Record<string, () => Promise<any>> = {
  FormatBold: () =>
    import(`../../../node_modules/vue-material-design-icons/FormatBold.vue`),
  FormatItalic: () =>
    import(`../../../node_modules/vue-material-design-icons/FormatItalic.vue`),
  FormatUnderline: () =>
    import(
      `../../../node_modules/vue-material-design-icons/FormatUnderline.vue`
    ),
  FormatHeader1: () =>
    import(`../../../node_modules/vue-material-design-icons/FormatHeader1.vue`),
  FormatHeader2: () =>
    import(`../../../node_modules/vue-material-design-icons/FormatHeader2.vue`),
  FormatHeader3: () =>
    import(`../../../node_modules/vue-material-design-icons/FormatHeader3.vue`),
  Link: () =>
    import(`../../../node_modules/vue-material-design-icons/Link.vue`),
  LinkOff: () =>
    import(`../../../node_modules/vue-material-design-icons/LinkOff.vue`),
  Image: () =>
    import(`../../../node_modules/vue-material-design-icons/Image.vue`),
  Information: () =>
    import(
      `../../../node_modules/vue-material-design-icons/InformationVariant.vue`
    ),
  FormatListBulleted: () =>
    import(
      `../../../node_modules/vue-material-design-icons/FormatListBulleted.vue`
    ),
  FormatListNumbered: () =>
    import(
      `../../../node_modules/vue-material-design-icons/FormatListNumbered.vue`
    ),
  FormatQuoteClose: () =>
    import(
      `../../../node_modules/vue-material-design-icons/FormatQuoteClose.vue`
    ),
  Undo: () =>
    import(`../../../node_modules/vue-material-design-icons/Undo.vue`),
  Redo: () =>
    import(`../../../node_modules/vue-material-design-icons/Redo.vue`),
  AccountCircle: () =>
    import(`../../../node_modules/vue-material-design-icons/AccountCircle.vue`),
  Upload: () =>
    import(`../../../node_modules/vue-material-design-icons/Upload.vue`),
  Chat: () =>
    import(`../../../node_modules/vue-material-design-icons/Chat.vue`),
  Calendar: () =>
    import(`../../../node_modules/vue-material-design-icons/Calendar.vue`),
  Cog: () => import(`../../../node_modules/vue-material-design-icons/Cog.vue`),
  AccountMultiplePlus: () =>
    import(
      `../../../node_modules/vue-material-design-icons/AccountMultiplePlus.vue`
    ),
  AccountMultipleMinus: () =>
    import(
      `../../../node_modules/vue-material-design-icons/AccountMultipleMinus.vue`
    ),
  AccountMultiple: () =>
    import(
      `../../../node_modules/vue-material-design-icons/AccountMultiple.vue`
    ),
  Bullhorn: () =>
    import(`../../../node_modules/vue-material-design-icons/Bullhorn.vue`),
  Delete: () =>
    import(`../../../node_modules/vue-material-design-icons/Delete.vue`),
  Alert: () =>
    import(`../../../node_modules/vue-material-design-icons/Alert.vue`),
  ChevronDown: () =>
    import(`../../../node_modules/vue-material-design-icons/ChevronDown.vue`),
  ChevronUp: () =>
    import(`../../../node_modules/vue-material-design-icons/ChevronUp.vue`),
  ChevronLeft: () =>
    import(`../../../node_modules/vue-material-design-icons/ChevronLeft.vue`),
  ChevronRight: () =>
    import(`../../../node_modules/vue-material-design-icons/ChevronRight.vue`),
  Reply: () =>
    import(`../../../node_modules/vue-material-design-icons/Reply.vue`),
  DotsHorizontal: () =>
    import(
      `../../../node_modules/vue-material-design-icons/DotsHorizontal.vue`
    ),
  Pencil: () =>
    import(`../../../node_modules/vue-material-design-icons/Pencil.vue`),
  Flag: () =>
    import(`../../../node_modules/vue-material-design-icons/Flag.vue`),
  ContentPaste: () =>
    import(`../../../node_modules/vue-material-design-icons/ContentPaste.vue`),
  Lock: () =>
    import(`../../../node_modules/vue-material-design-icons/Lock.vue`),
  Google: () =>
    import(`../../../node_modules/vue-material-design-icons/Google.vue`),
  MenuDown: () =>
    import(`../../../node_modules/vue-material-design-icons/MenuDown.vue`),
  MenuUp: () =>
    import(`../../../node_modules/vue-material-design-icons/MenuUp.vue`),
  Check: () =>
    import(`../../../node_modules/vue-material-design-icons/Check.vue`),
  TimerSandEmpty: () =>
    import(
      `../../../node_modules/vue-material-design-icons/TimerSandEmpty.vue`
    ),
  Earth: () =>
    import(`../../../node_modules/vue-material-design-icons/Earth.vue`),
  Map: () => import(`../../../node_modules/vue-material-design-icons/Map.vue`),
  MapMarker: () =>
    import(`../../../node_modules/vue-material-design-icons/MapMarker.vue`),
  MapMarkerDistance: () =>
    import(
      `../../../node_modules/vue-material-design-icons/MapMarkerDistance.vue`
    ),
  Close: () =>
    import(`../../../node_modules/vue-material-design-icons/Close.vue`),
  Magnify: () =>
    import(`../../../node_modules/vue-material-design-icons/Magnify.vue`),
  Loading: () =>
    import(`../../../node_modules/vue-material-design-icons/Loading.vue`),
  Eye: () => import(`../../../node_modules/vue-material-design-icons/Eye.vue`),
  EyeOff: () =>
    import(`../../../node_modules/vue-material-design-icons/EyeOff.vue`),
  AlertCircle: () =>
    import(`../../../node_modules/vue-material-design-icons/AlertCircle.vue`),
  Rss: () => import(`../../../node_modules/vue-material-design-icons/Rss.vue`),
  CalendarSync: () =>
    import(`../../../node_modules/vue-material-design-icons/CalendarSync.vue`),
  OpenInNew: () =>
    import(`../../../node_modules/vue-material-design-icons/OpenInNew.vue`),
  Home: () =>
    import(`../../../node_modules/vue-material-design-icons/Home.vue`),
  Send: () =>
    import(`../../../node_modules/vue-material-design-icons/Send.vue`),
  Comment: () =>
    import(`../../../node_modules/vue-material-design-icons/Comment.vue`),
  Label: () =>
    import(`../../../node_modules/vue-material-design-icons/Label.vue`),
  CalendarToday: () =>
    import(`../../../node_modules/vue-material-design-icons/CalendarToday.vue`),
  WheelchairAccessibility: () =>
    import(
      `../../../node_modules/vue-material-design-icons/WheelchairAccessibility.vue`
    ),
  Youtube: () =>
    import(`../../../node_modules/vue-material-design-icons/Youtube.vue`),
  Twitch: () =>
    import(`../../../node_modules/vue-material-design-icons/Twitch.vue`),
  Twitter: () =>
    import(`../../../node_modules/vue-material-design-icons/Twitter.vue`),
  MicrosoftTeams: () =>
    import(
      `../../../node_modules/vue-material-design-icons/MicrosoftTeams.vue`
    ),
  GoogleHangouts: () =>
    import(
      `../../../node_modules/vue-material-design-icons/GoogleHangouts.vue`
    ),
  Webcam: () =>
    import(`../../../node_modules/vue-material-design-icons/Webcam.vue`),
  TicketConfirmation: () =>
    import(
      `../../../node_modules/vue-material-design-icons/TicketConfirmation.vue`
    ),
  CalendarCheck: () =>
    import(`../../../node_modules/vue-material-design-icons/CalendarCheck.vue`),
  CalendarText: () =>
    import(`../../../node_modules/vue-material-design-icons/CalendarText.vue`),
  CalendarQuestion: () =>
    import(
      `../../../node_modules/vue-material-design-icons/CalendarQuestion.vue`
    ),
  CalendarRemove: () =>
    import(
      `../../../node_modules/vue-material-design-icons/CalendarRemove.vue`
    ),
  CalendarStar: () =>
    import(`../../../node_modules/vue-material-design-icons/CalendarStar.vue`),
  FileDocumentEdit: () =>
    import(
      `../../../node_modules/vue-material-design-icons/FileDocumentEdit.vue`
    ),
  Subtitles: () =>
    import(`../../../node_modules/vue-material-design-icons/Subtitles.vue`),
  HelpCircleOutline: () =>
    import(
      `../../../node_modules/vue-material-design-icons/HelpCircleOutline.vue`
    ),
  Cash: () =>
    import(`../../../node_modules/vue-material-design-icons/Cash.vue`),
  ArrowUp: () =>
    import(`../../../node_modules/vue-material-design-icons/ArrowUp.vue`),
  Share: () =>
    import(`../../../node_modules/vue-material-design-icons/Share.vue`),
  TimelineText: () =>
    import(`../../../node_modules/vue-material-design-icons/TimelineText.vue`),
  Account: () =>
    import(`../../../node_modules/vue-material-design-icons/Account.vue`),
  City: () =>
    import(`../../../node_modules/vue-material-design-icons/City.vue`),
  ChevronDoubleUp: () =>
    import(
      `../../../node_modules/vue-material-design-icons/ChevronDoubleUp.vue`
    ),
  ChevronDoubleDown: () =>
    import(
      `../../../node_modules/vue-material-design-icons/ChevronDoubleDown.vue`
    ),
  GoogleSpreadsheet: () =>
    import(
      `../../../node_modules/vue-material-design-icons/GoogleSpreadsheet.vue`
    ),
  FilePdfBox: () =>
    import(`../../../node_modules/vue-material-design-icons/FilePdfBox.vue`),
  FileDelimited: () =>
    import(`../../../node_modules/vue-material-design-icons/FileDelimited.vue`),
  FileDocumentOutline: () =>
    import(
      `../../../node_modules/vue-material-design-icons/FileDocumentOutline.vue`
    ),
  Refresh: () =>
    import(`../../../node_modules/vue-material-design-icons/Refresh.vue`),
  RoadVariant: () =>
    import(`../../../node_modules/vue-material-design-icons/RoadVariant.vue`),
  AccountGroup: () =>
    import(`../../../node_modules/vue-material-design-icons/AccountGroup.vue`),
  Web: () => import(`../../../node_modules/vue-material-design-icons/Web.vue`),
  Email: () =>
    import(`../../../node_modules/vue-material-design-icons/Email.vue`),
  ChatAlert: () =>
    import(`../../../node_modules/vue-material-design-icons/ChatAlert.vue`),
  InboxArrowDown: () =>
    import(
      `../../../node_modules/vue-material-design-icons/InboxArrowDown.vue`
    ),
  InboxArrowUp: () =>
    import(`../../../node_modules/vue-material-design-icons/InboxArrowUp.vue`),
  LanDisconnect: () =>
    import(`../../../node_modules/vue-material-design-icons/LanDisconnect.vue`),
  CloudQuestion: () =>
    import(`../../../node_modules/vue-material-design-icons/CloudQuestion.vue`),
  Filter: () =>
    import(`../../../node_modules/vue-material-design-icons/Filter.vue`),
  CheckCircle: () =>
    import(`../../../node_modules/vue-material-design-icons/CheckCircle.vue`),
  ViewList: () =>
    import(`../../../node_modules/vue-material-design-icons/ViewList.vue`),
  SmokingOff: () =>
    import(`../../../node_modules/vue-material-design-icons/SmokingOff.vue`),
  BellOutline: () =>
    import(`../../../node_modules/vue-material-design-icons/BellOutline.vue`),
  BellOffOutline: () =>
    import(
      `../../../node_modules/vue-material-design-icons/BellOffOutline.vue`
    ),
  ExitToApp: () =>
    import(`../../../node_modules/vue-material-design-icons/ExitToApp.vue`),
  CheckboxMarked: () =>
    import(
      `../../../node_modules/vue-material-design-icons/CheckboxMarked.vue`
    ),
  EyeOutline: () =>
    import(`../../../node_modules/vue-material-design-icons/EyeOutline.vue`),
  PencilOutline: () =>
    import(`../../../node_modules/vue-material-design-icons/PencilOutline.vue`),
  Apps: () =>
    import(`../../../node_modules/vue-material-design-icons/Apps.vue`),
  Server: () =>
    import(`../../../node_modules/vue-material-design-icons/Server.vue`),
};

const props = withDefaults(
  defineProps<{
    icon: string[] | string;
    size?: string;
    type?: string;
  }>(),
  { size: "18" }
);

const name = computed(() => toPascalCase(props.icon[1]));

const componentInstance = computed(() => {
  if (Object.prototype.hasOwnProperty.call(icons, name.value)) {
    return defineAsyncComponent(icons[name.value]);
  } else {
    console.error("Icon is undefined", name.value);
    return undefined;
  }
});

const realSize = computed(() => Number.parseInt(props.size ?? "18"));

function toPascalCase(text: string) {
  return text.replace(/(^\w|-\w)/g, clearAndUpper);
}

function clearAndUpper(text: string) {
  return text.replace(/-/, "").toUpperCase();
}
</script>
