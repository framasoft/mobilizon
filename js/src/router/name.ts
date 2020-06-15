import { EventRouteName } from "./event";
import { ActorRouteName } from "./actor";
import { ErrorRouteName } from "./error";
import { SettingsRouteName } from "./settings";
import { GroupsRouteName } from "./groups";
import { ConversationRouteName } from "./conversation";
import { UserRouteName } from "./user";

enum GlobalRouteName {
  HOME = "Home",
  ABOUT = "About",
  PAGE_NOT_FOUND = "PageNotFound",
  SEARCH = "Search",
  TERMS = "TERMS",
  INTERACT = "INTERACT",
  RULES = "RULES",
}

// Hack to merge enums
// tslint:disable:variable-name
export default {
  ...GlobalRouteName,
  ...UserRouteName,
  ...EventRouteName,
  ...ActorRouteName,
  ...SettingsRouteName,
  ...GroupsRouteName,
  ...ConversationRouteName,
  ...ErrorRouteName,
};
