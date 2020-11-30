<docs>
```vue
<report-card :report="{ reported: { name: 'Some bad guy', preferredUsername: 'kevin' }, reporter: { preferredUsername: 'somePerson34' }, reportContent: 'This is not good'}" />
```
</docs>
<template>
  <div class="card" v-if="report">
    <div class="card-content">
      <div class="media">
        <div class="media-left">
          <figure class="image is-48x48" v-if="report.reported.avatar">
            <img alt="" :src="report.reported.avatar.url" />
          </figure>
          <b-icon v-else size="is-large" icon="account-circle" />
        </div>
        <div class="media-content">
          <p class="title is-4">{{ report.reported.name }}</p>
          <p class="subtitle is-6">@{{ report.reported.preferredUsername }}</p>
        </div>
      </div>

      <div class="content columns">
        <div class="column is-one-quarter-desktop">
          <span v-if="report.reporter.type === ActorType.APPLICATION">
            {{
              $t("Reported by someone on {domain}", {
                domain: report.reporter.domain,
              })
            }}
          </span>
          <span v-else>
            {{
              $t("Reported by {reporter}", {
                reporter: report.reporter.preferredUsername,
              })
            }}
          </span>
        </div>
        <div class="column" v-if="report.content" v-html="report.content" />
      </div>
    </div>
  </div>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { IReport } from "@/types/report.model";
import { ActorType } from "@/types/enums";

@Component
export default class ReportCard extends Vue {
  @Prop({ required: true }) report!: IReport;

  ActorType = ActorType;
}
</script>
<style lang="scss">
.content img.image {
  display: inline;
  height: 1.5em;
  vertical-align: text-bottom;
}
</style>
