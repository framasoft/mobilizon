import { EventRouteName } from "./event";
import { ActorRouteName } from "./actor";
import { ErrorRouteName } from "./error";
import { SettingsRouteName } from "./settings";
import { GroupsRouteName } from "./groups";
import { DiscussionRouteName } from "./discussion";
import { UserRouteName } from "./user";

enum GlobalRouteName {
  HOME = "Home",
  ABOUT = "About",
  ABOUT_INSTANCE = "ABOUT_INSTANCE",
  PAGE_NOT_FOUND = "PageNotFound",
  SEARCH = "Search",
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
  ...ErrorRouteName,
};
