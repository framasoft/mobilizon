import { FILTER_TAGS } from "@/graphql/tags";
import { ITag } from "@/types/tag.model";
import { useLazyQuery } from "@vue/apollo-composable";

export function useFetchTags() {
  return useLazyQuery<{ tags: ITag[] }, { filter: string }>(FILTER_TAGS);
}
