import { IActivity } from "@/types/activity.model";
import { IMember } from "@/types/actor/member.model";
import { useCurrentActorClient } from "./apollo/actor";

export function useIsActivityAuthorCurrentActor() {
  const { currentActor } = useCurrentActorClient();

  return (activity: IActivity): boolean => {
    return (
      activity.author.id === currentActor.value?.id &&
      currentActor.value?.id !== undefined
    );
  };
}

export function useIsActivityObjectCurrentActor() {
  const { currentActor } = useCurrentActorClient();
  return (activity: IActivity): boolean =>
    (activity?.object as IMember)?.actor?.id === currentActor.value?.id &&
    currentActor.value?.id !== undefined;
}

export function useActivitySubjectParams() {
  return (activity: IActivity) =>
    activity.subjectParams.reduce(
      (acc: Record<string, string>, { key, value }) => {
        acc[key] = value;
        return acc;
      },
      {}
    );
}
