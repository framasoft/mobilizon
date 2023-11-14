import { FILTER_TAGS } from "@/graphql/tags";
import { ITag } from "@/types/tag.model";
import { apolloClient } from "@/vue-apollo";
import { provideApolloClient, useLazyQuery } from "@vue/apollo-composable";

export async function fetchTags(text: string): Promise<ITag[]> {
  try {
    const { load: loadFetchTagsQuery } = useLazyQuery<
      { tags: ITag[] },
      { filter: string }
    >(FILTER_TAGS);

    const res = await provideApolloClient(apolloClient)(() =>
      loadFetchTagsQuery(FILTER_TAGS, {
        filter: text,
      })
    );
    if (!res) return [];
    return res.tags;
  } catch (e) {
    console.error(e);
    return [];
  }
}
