<template>
  <div class="container mx-auto section">
    <breadcrumbs-nav :links="[]" />
    <section>
      <h1>{{ t("Announcements") }}</h1>
      <div v-if="conversations.elements.length > 0">
        <announcement-list-item
          :announcement="conversation"
          v-for="conversation in conversations.elements"
          :key="conversation.id"
        />
        <o-pagination
          v-show="conversations.total > CONVERSATIONS_PER_PAGE"
          class="conversation-pagination"
          :total="conversations.total"
          v-model:current="page"
          :per-page="CONVERSATIONS_PER_PAGE"
          :aria-next-label="t('Next page')"
          :aria-previous-label="t('Previous page')"
          :aria-page-label="t('Page')"
          :aria-current-label="t('Current page')"
        >
        </o-pagination>
      </div>
      <empty-content v-else icon="bullhorn" inline>
        {{ t("There's no announcements yet") }}
      </empty-content>
    </section>
  </div>
</template>
<script lang="ts" setup>
import AnnouncementListItem from "../../components/Conversations/AnnouncementListItem.vue";
import EmptyContent from "../../components/Utils/EmptyContent.vue";
import { useI18n } from "vue-i18n";
import { useRouteQuery, integerTransformer } from "vue-use-route-query";
import { computed } from "vue";
import { IEvent } from "../../types/event.model";
import { EVENT_CONVERSATIONS } from "../../graphql/event";
import { useQuery } from "@vue/apollo-composable";

const page = useRouteQuery("page", 1, integerTransformer);
const CONVERSATIONS_PER_PAGE = 10;

const props = defineProps<{ event: IEvent }>();
const event = computed(() => props.event);

const { t } = useI18n({ useScope: "global" });

const { result: conversationsResult } = useQuery<{
  event: Pick<IEvent, "conversations">;
}>(EVENT_CONVERSATIONS, () => ({
  uuid: event.value.uuid,
  page: page.value,
}));

const conversations = computed(
  () =>
    conversationsResult.value?.event.conversations || { elements: [], total: 0 }
);
</script>
