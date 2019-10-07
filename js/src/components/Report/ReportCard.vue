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
                        <img :src="report.reported.avatar.url" />
                    </figure>
                </div>
                <div class="media-content">
                    <p class="title is-4">{{ report.reported.name }}</p>
                    <p class="subtitle is-6">@{{ report.reported.preferredUsername }}</p>
                </div>
            </div>

            <div class="content columns">
                <div class="column is-one-quarter box">Reported by <img v-if="report.reporter.avatar" class="image" :src="report.reporter.avatar.url" /> @{{ report.reporter.preferredUsername }}</div>
                <div class="column box" v-if="report.event">
                    <img class="image" v-if="report.event.picture" :src="report.event.picture.url" />
                    <span>{{ report.event.title }}</span>
                </div>
                <div class="column box" v-if="report.reportContent">{{ report.reportContent }}</div>
            </div>
        </div>
    </div>
</template>
<script lang="ts">
import { Component, Prop, Vue } from 'vue-property-decorator';
import { IReport } from '@/types/report.model';

@Component
export default class ReportCard extends Vue {
  @Prop({ required: true }) report!: IReport;
}
</script>
<style lang="scss">
    .content img.image {
        display: inline;
        height: 1.5em;
        vertical-align: text-bottom;
    }
</style>