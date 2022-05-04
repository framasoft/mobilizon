<template>
  <div class="participation-button">
    <a
      class="button is-large is-primary"
      type="button"
      target="_blank"
      :href="
        event.externalParticipationUrl
          ? encodeURI(`${event.externalParticipationUrl}?uuid=${event.uuid}`)
          : '#'
      "
      :disabled="!event.externalParticipationUrl"
      >{{ $t("Go to booking") }}&nbsp;
      <b-icon style="margin-left: 0" icon="open-in-new"
    /></a>
  </div>
</template>

<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { IEvent } from "../../types/event.model";

@Component
export default class ExternalParticipationButton extends Vue {
  @Prop({ required: true }) event!: IEvent;
}
</script>
