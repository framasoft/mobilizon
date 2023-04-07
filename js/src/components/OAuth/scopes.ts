import { i18n } from "@/utils/i18n";

const t = i18n.global.t;

export const scope: Record<
  string,
  { title: string; type?: "warning"; text: string; icon?: string }
> = {
  read: {
    title: t("Read all of your account's data"),
    type: "warning",
    text: t(
      "This application will be allowed to see all of your events organized, the events you participate to, as well as every data from your groups."
    ),
    icon: "eye-outline",
  },
  write: {
    title: t("Modify all of your account's data"),
    text: t(
      "This application will be allowed to publish and manage events, post and manage comments, participate to events, manage all of your groups, including group events, resources, posts and discussions. It will also be allowed to manage your account and profile settings."
    ),
    type: "warning",
    icon: "pencil-outline",
  },
  "write:event:create": {
    title: t("Publish events"),
    text: t(
      "This application will be allowed to publish events"
    ),
    icon: "calendar",
  },
  "write:event:update": {
    title: t("Update events"),
    text: t("This application will be allowed to update events"),
    icon: "calendar",
  },
  "write:event:delete": {
    title: t("Delete events"),
    text: t("This application will be allowed to delete events"),
    icon: "calendar",
  },
  "write:media:upload": {
    title: t("Upload media"),
    text: t("This application will be allowed to upload media"),
    icon: "image",
  },
  "write:media:remove": {
    title: t("Remove uploaded media"),
    text: t(
      "This application will be allowed to remove uploaded media"
    ),
    icon: "image",
  },
  "write:group:post:create": {
    title: t("Publish group posts"),
    text: t(
      "This application will be allowed to publish group posts"
    ),
    icon: "bullhorn",
  },
  "write:group:post:update": {
    title: t("Update group posts"),
    text: t(
      "This application will be allowed to update group posts"
    ),
    icon: "bullhorn",
  },
  "write:group:post:delete": {
    title: t("Delete group posts"),
    text: t(
      "This application will be allowed to delete group posts"
    ),
    icon: "bullhorn",
  },
  "read:group:resources": {
    title: t("Access your group's resources"),
    text: t(
      "This application will be allowed to access all of the groups you're a member of"
    ),
    icon: "link",
  },
  "write:group:resources:create": {
    title: t("Create group resources"),
    text: t(
      "This application will be allowed to create resources in all of the groups you're a member of"
    ),
    icon: "link",
  },
  "write:group:resources:update": {
    title: t("Update group resources"),
    text: t(
      "This application will be allowed to update resources in all of the groups you're a member of"
    ),
    icon: "link",
  },
  "write:group:resources:delete": {
    title: t("Delete group resources"),
    text: t(
      "This application will be allowed to delete resources in all of the groups you're a member of"
    ),
    icon: "link",
  },
  "read:group:events": {
    title: t("Access group events"),
    text: t(
      "This application will be allowed to list and access group events in all of the groups you're a member of"
    ),
    icon: "calendar",
  },
  "read:group:discussions": {
    title: t("Access group discussions"),
    text: t(
      "This application will be allowed to list and access group discussions in all of the groups you're a member of"
    ),
    icon: "chat",
  },
  "read:group:members": {
    title: t("Access group members"),
    text: t(
      "This application will be allowed to list group members in all of the groups you're a member of"
    ),
    icon: "account-circle",
  },
  "read:group:followers": {
    title: t("Access group followers"),
    text: t(
      "This application will be allowed to list group followers in all of the groups you're a member of"
    ),
    icon: "account-circle",
  },
  "read:group:activities": {
    title: t("Access group activities"),
    text: t(
      "This application will be allowed to access group activities in all of the groups you're a member of"
    ),
    icon: "timeline-text",
  },
  "read:group:todo_lists": {
    title: t("Access group todo-lists"),
    text: t(
      "This application will be allowed to list and access group todo-lists in all of the groups you're a member of"
    ),
    icon: "checkbox-marked",
  },
  "write:group:group_membership": {
    title: t("Manage group memberships"),
    text: t(
      "This application will be allowed to join and leave groups"
    ),
    icon: "account-circle",
  },
  "write:group:members": {
    title: t("Manage group members"),
    text: t(
      "This application will be allowed to manage group members in all of the groups you're a member of"
    ),
    icon: "account-circle",
  },
  "read:profile:organized_events": {
    title: t("Access organized events"),
    text: t(
      "This application will be allowed to list and view your organized events"
    ),
    icon: "calendar",
  },
  "read:profile:participations": {
    title: t("Access participations"),
    text: t(
      "This application will be allowed to list and view the events you're participating to"
    ),
    icon: "account-circle",
  },
  "read:profile:memberships": {
    title: t("Access group memberships"),
    text: t(
      "This application will be allowed to list and view the groups you're a member of"
    ),
    icon: "account-circle",
  },
  "read:profile:follows": {
    title: t("Access followed groups"),
    text: t(
      "This application will be allowed to list and view the groups you're following"
    ),
    icon: "account-circle",
  },
  "write:profile:create": {
    title: t("Create new profiles"),
    text: t(
      "This application will be allowed to create new profiles for your account"
    ),
    icon: "account-circle",
  },
  "write:profile:update": {
    title: t("Update profiles"),
    text: t(
      "This application will be allowed to update your profiles"
    ),
    icon: "account-circle",
  },
  "write:profile:delete": {
    title: t("Delete profiles"),
    text: t(
      "This application will be allowed to delete your profiles"
    ),
    icon: "account-circle",
  },
  "write:comment:create": {
    title: t("Post comments"),
    text: t("This application will be allowed to post comments"),
    icon: "comment",
  },
  "write:comment:update": {
    title: t("Update comments"),
    text: t(
      "This application will be allowed to update comments"
    ),
    icon: "comment",
  },
  "write:comment:delete": {
    title: t("Delete comments"),
    text: t(
      "This application will be allowed to delete comments"
    ),
    icon: "comment",
  },
  "write:group:discussion:create": {
    title: t("Create group discussions"),
    text: t(
      "This application will be allowed to create group discussions"
    ),
    icon: "comment",
  },
  "write:group:discussion:update": {
    title: t("Update group discussions"),
    text: t(
      "This application will be allowed to update group discussions"
    ),
    icon: "comment",
  },
  "write:group:discussion:delete": {
    title: t("Delete group discussions"),
    text: t(
      "This application will be allowed to delete group discussions"
    ),
    icon: "comment",
  },
  "write:profile:feed_token:create": {
    title: t("Create feed tokens"),
    text: t(
      "This application will be allowed to create feed tokens"
    ),
    icon: "rss",
  },
  "write:feed_token:delete": {
    title: t("Delete feed tokens"),
    text: t(
      "This application will be allowed to delete feed tokens"
    ),
    icon: "rss",
  },
  "write:participation": {
    title: t("Manage event participations"),
    text: t(
      "This application will be allowed to manage events participations"
    ),
    icon: "rss",
  },
  "write:user:setting:activity": {
    title: t("Manage activity settings"),
    text: t(
      "This application will be allowed to manage your account activity settings"
    ),
    icon: "cog",
  },
  "write:user:setting:push": {
    title: t("Manage push notification settings"),
    text: t(
      "This application will be allowed to manage your account push notification settings"
    ),
    icon: "cog",
  },
};
