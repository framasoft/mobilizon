import { FILTER_TAGS } from "@/graphql/tags";
import { ITag } from "@/types/tag.model";
import { apolloClient } from "@/vue-apollo";
import { provideApolloClient, useQuery } from "@vue/apollo-composable";

export function fetchTags(text: string): Promise<ITag[]> {
  return new Promise((resolve, reject) => {
    const { onResult, onError } = provideApolloClient(apolloClient)(() =>
      useQuery<{ tags: ITag[] }, { filter: string }>(FILTER_TAGS, {
        filter: text,
      })
    );

    onResult((result) => {
      if (result.loading) {
        return;
      }
      return resolve(result.data.tags);
    });

    onError((error) => reject(error));
  });
}
