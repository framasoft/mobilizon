import { CREATE_REPORT } from "@/graphql/report";
import { useMutation } from "@vue/apollo-composable";

export function useCreateReport() {
  return useMutation<
    { createReport: { id: string } },
    {
      eventsIds?: string[];
      reportedId: string;
      content?: string;
      commentsIds?: string[];
      forward?: boolean;
    }
  >(CREATE_REPORT);
}
