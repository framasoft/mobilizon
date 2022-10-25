<template>
  <div
    class="bg-mbz-yellow-alt-50 hover:bg-mbz-yellow-alt-100 dark:bg-zinc-700 hover:dark:bg-zinc-600 rounded"
    v-if="report"
  >
    <div class="flex justify-between gap-1 border-b p-2">
      <div class="flex gap-1">
        <figure class="" v-if="report.reported.avatar">
          <img
            alt=""
            :src="report.reported.avatar.url"
            class="rounded-full"
            width="24"
            height="24"
          />
        </figure>
        <AccountCircle v-else :size="24" />
        <div class="">
          <p class="" v-if="report.reported.name">{{ report.reported.name }}</p>
          <p class="text-zinc-700 dark:text-zinc-100 text-sm">
            @{{ usernameWithDomain(report.reported) }}
          </p>
        </div>
      </div>
      <div>
        <p v-if="report.reported.suspended" class="text-red-700 font-bold">
          {{ t("Suspended") }}
        </p>
      </div>
    </div>

    <div class="p-2">
      <div class="">
        <span v-if="report.reporter.type === ActorType.APPLICATION">
          {{
            t("Reported by someone on {domain}", {
              domain: report.reporter.domain,
            })
          }}
        </span>
        <span
          v-if="
            report.reporter.preferredUsername === 'anonymous' &&
            !report.reporter.domain
          "
        >
          {{ t("Reported by someone anonymously") }}
        </span>
        <span v-else>
          {{
            t("Reported by {reporter}", {
              reporter: usernameWithDomain(report.reporter),
            })
          }}
        </span>
      </div>
      <div class="" v-if="report.content" v-html="report.content" />
    </div>
  </div>
</template>
<script lang="ts" setup>
import { IReport } from "@/types/report.model";
import { ActorType } from "@/types/enums";
import { useI18n } from "vue-i18n";
import AccountCircle from "vue-material-design-icons/AccountCircle.vue";
import { usernameWithDomain } from "@/types/actor";

defineProps<{
  report: IReport;
}>();

const { t } = useI18n({ useScope: "global" });
</script>
<style lang="scss">
.content img.image {
  display: inline;
  height: 1.5em;
  vertical-align: text-bottom;
}
</style>
