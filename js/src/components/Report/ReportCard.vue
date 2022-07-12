<template>
  <div class="" v-if="report">
    <div class="flex gap-1">
      <figure class="" v-if="report.reported.avatar">
        <img
          alt=""
          :src="report.reported.avatar.url"
          class="rounded-full"
          width="48"
          height="48"
        />
      </figure>
      <AccountCircle v-else :size="48" />
      <div class="">
        <p class="" v-if="report.reported.name">{{ report.reported.name }}</p>
        <p class="">@{{ usernameWithDomain(report.reported) }}</p>
      </div>
    </div>

    <div class="reported_by">
      <div class="">
        <span v-if="report.reporter.type === ActorType.APPLICATION">
          {{
            t("Reported by someone on {domain}", {
              domain: report.reporter.domain,
            })
          }}
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
