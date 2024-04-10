import { computed } from "vue";
import { provideApolloClient, useQuery } from "@vue/apollo-composable";
import { useHead as unHead } from "@unhead/vue";
import { apolloClient } from "@/vue-apollo";
import { IConfig } from "@/types/config.model";
import { ABOUT } from "@/graphql/config";

const { result } = provideApolloClient(apolloClient)(() =>
  useQuery<{ config: Pick<IConfig, "name"> }>(ABOUT)
);
const instanceName = computed(() => result.value?.config?.name);

export function useHead(args: any) {
  return unHead({
    ...args,
    title: computed(() =>
      args?.title?.value
        ? `${args.title.value} - ${instanceName.value}`
        : instanceName.value
    ),
  });
}
