import { IResource } from "@/types/resource";

export const resourcePath = (resource: IResource | undefined): string => {
  const path = resource?.path ?? undefined;
  if (path && path[0] === "/") {
    return path.slice(1);
  }
  return path ?? "";
};

export const resourcePathArray = (
  resource: IResource | undefined
): string[] => {
  return resourcePath(resource).split("/");
};
