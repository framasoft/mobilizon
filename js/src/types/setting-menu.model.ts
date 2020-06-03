import { Route } from "vue-router";

export interface ISettingMenuSection {
  title: string;
  to: Route;
  items?: ISettingMenuSection[];
  parents?: ISettingMenuSection[];
}
