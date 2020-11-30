<template>
  <div>
    <div class="media" style="align-items: top">
      <div class="media-left">
        <figure class="image is-32x32" v-if="actor.avatar">
          <img class="is-rounded" :src="actor.avatar.url" alt="" />
        </figure>
        <b-icon v-else size="is-medium" icon="account-circle" />
      </div>

      <div class="media-content">
        <p>
          {{ actor.name || `@${usernameWithDomain(actor)}` }}
        </p>
        <p class="has-text-grey" v-if="actor.name">
          @{{ usernameWithDomain(actor) }}
        </p>
        <div
          v-if="full"
          class="summary"
          :class="{ limit: limit }"
          v-html="actor.summary"
        />
      </div>
    </div>
  </div>
</template>
<script lang="ts">
import { Component, Vue, Prop } from "vue-property-decorator";
import { IActor, usernameWithDomain } from "../../types/actor";

@Component
export default class ActorCard extends Vue {
  @Prop({ required: true, type: Object }) actor!: IActor;

  @Prop({ required: false, type: Boolean, default: false }) full!: boolean;

  @Prop({ required: false, type: Boolean, default: false }) popover!: boolean;

  @Prop({ required: false, type: Boolean, default: true }) limit!: boolean;

  usernameWithDomain = usernameWithDomain;
}
</script>
<style lang="scss" scoped>
.summary.limit {
  max-width: 25rem;
  display: -webkit-box;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: 3;
  overflow: hidden;
}
</style>

<style lang="scss">
.tooltip {
  display: block !important;
  z-index: 10000;

  .tooltip-inner {
    background: black;
    color: white;
    border-radius: 16px;
    padding: 5px 10px 4px;
  }

  .tooltip-arrow {
    width: 0;
    height: 0;
    border-style: solid;
    position: absolute;
    margin: 5px;
    border-color: black;
    z-index: 1;
  }

  &[x-placement^="top"] {
    margin-bottom: 5px;

    .tooltip-arrow {
      border-width: 5px 5px 0 5px;
      border-left-color: transparent !important;
      border-right-color: transparent !important;
      border-bottom-color: transparent !important;
      bottom: -5px;
      left: calc(50% - 5px);
      margin-top: 0;
      margin-bottom: 0;
    }
  }

  &[x-placement^="bottom"] {
    margin-top: 5px;

    .tooltip-arrow {
      border-width: 0 5px 5px 5px;
      border-left-color: transparent !important;
      border-right-color: transparent !important;
      border-top-color: transparent !important;
      top: -5px;
      left: calc(50% - 5px);
      margin-top: 0;
      margin-bottom: 0;
    }
  }

  &[x-placement^="right"] {
    margin-left: 5px;

    .tooltip-arrow {
      border-width: 5px 5px 5px 0;
      border-left-color: transparent !important;
      border-top-color: transparent !important;
      border-bottom-color: transparent !important;
      left: -5px;
      top: calc(50% - 5px);
      margin-left: 0;
      margin-right: 0;
    }
  }

  &[x-placement^="left"] {
    margin-right: 5px;

    .tooltip-arrow {
      border-width: 5px 0 5px 5px;
      border-top-color: transparent !important;
      border-right-color: transparent !important;
      border-bottom-color: transparent !important;
      right: -5px;
      top: calc(50% - 5px);
      margin-left: 0;
      margin-right: 0;
    }
  }

  &.popover {
    $color: #f9f9f9;

    .popover-inner {
      background: lighten($background-color, 65%);
      color: black;
      padding: 24px;
      border-radius: 5px;
      box-shadow: 0 5px 30px rgba(black, 0.1);
    }

    .popover-arrow {
      border-color: $color;
    }
  }

  &[aria-hidden="true"] {
    visibility: hidden;
    opacity: 0;
    transition: opacity 0.15s, visibility 0.15s;
  }

  &[aria-hidden="false"] {
    visibility: visible;
    opacity: 1;
    transition: opacity 0.15s;
  }
}
</style>
