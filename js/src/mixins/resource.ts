import { Component, Vue } from "vue-property-decorator";
import { IResource } from "@/types/resource";

@Component
export default class ResourceMixin extends Vue {
  static resourcePath(resource: IResource): string {
    const { path } = resource;
    if (path && path[0] === "/") {
      return path.slice(1);
    }
    return path || "";
  }

  static resourcePathArray(resource: IResource): string[] {
    return ResourceMixin.resourcePath(resource).split("/");
  }
}
