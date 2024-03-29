import { EventRouteName } from "./event";
import { ActorRouteName } from "./actor";
import { ErrorRouteName } from "./error";
import { SettingsRouteName } from "./settings";
import { GroupsRouteName } from "./groups";
import { DiscussionRouteName } from "./discussion";
import { ConversationRouteName } from "./conversation";
import { UserRouteName } from "./user";

enum GlobalRouteName {
  HOME = "HOME",
  ABOUT = "ABOUT",
  CATEGORIES = "CATEGORIES",
  ABOUT_INSTANCE = "ABOUT_INSTANCE",
  PAGE_NOT_FOUND = "PageNotFound",
  SEARCH = "SEARCH",
  TERMS = "TERMS",
  PRIVACY = "PRIVACY",
  GLOSSARY = "GLOSSARY",
  INTERACT = "INTERACT",
  RULES = "RULES",
  WELCOME_SCREEN = "WELCOME_SCREEN",
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
  ...DiscussionRouteName,
  ...ConversationRouteName,
  ...ErrorRouteName,
};
