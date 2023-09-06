import { FILTER_TAGS } from "@/graphql/tags";
import { ITag } from "@/types/tag.model";
import { apolloClient, waitApolloQuery } from "@/vue-apollo";
import { provideApolloClient, useQuery } from "@vue/apollo-composable";

export async function fetchTags(text: string): Promise<ITag[]> {
  try {
    const res = await waitApolloQuery(
      provideApolloClient(apolloClient)(() =>
        useQuery<{ tags: ITag[] }, { filter: string }>(FILTER_TAGS, {
          filter: text,
        })
      )
    );
    return res.data.tags;
  } catch (e) {
    console.error(e);
    return [];
  }
}
