<template>
  <div
    class="w-80 bg-white rounded-lg shadow-md p-4 sm:p-8 flex items-center space-x-4 flex-col items-center pb-10"
  >
    <figure class="w-12 h-12" v-if="actor.avatar">
      <img
        class="rounded-lg"
        :src="actor.avatar.url"
        alt=""
        width="48"
        height="48"
      />
    </figure>
    <b-icon
      v-else
      size="is-large"
      icon="account-circle"
      class="ltr:-mr-0.5 rtl:-ml-0.5"
    />
    <h5 class="text-xl font-medium violet-title tracking-tight text-gray-900">
      {{ displayName(actor) }}
    </h5>
    <p class="text-gray-500 truncate" v-if="actor.name">
      <span dir="ltr">@{{ usernameWithDomain(actor) }}</span>
    </p>
    <div
      v-if="full"
      :class="{ 'line-clamp-3': limit }"
      v-html="actor.summary"
    />
  </div>
  <!-- <div
    class="p-4 bg-white rounded-lg shadow-md sm:p-8 flex items-center space-x-4"
    dir="auto"
  >
    <div class="flex-shrink-0">
      <figure class="w-12 h-12" v-if="actor.avatar">
        <img
          class="rounded-lg"
          :src="actor.avatar.url"
          alt=""
          width="48"
          height="48"
        />
      </figure>
      <b-icon
        v-else
        size="is-large"
        icon="account-circle"
        class="ltr:-mr-0.5 rtl:-ml-0.5"
      />
    </div>

    <div class="flex-1 min-w-0">
      <h5 class="text-xl font-medium violet-title tracking-tight text-gray-900">
        {{ displayName(actor) }}
      </h5>
      <p class="text-gray-500 truncate" v-if="actor.name">
        <span dir="ltr">@{{ usernameWithDomain(actor) }}</span>
      </p>
      <div
        v-if="full"
        class="line-clamp-3"
        :class="{ limit: limit }"
        v-html="actor.summary"
      />
    </div>
  </div> -->
</template>
<script lang="ts">
import { Component, Vue, Prop } from "vue-property-decorator";
import { displayName, IActor, usernameWithDomain } from "../../types/actor";

@Component
export default class ActorCard extends Vue {
  @Prop({ required: true, type: Object }) actor!: IActor;

  @Prop({ required: false, type: Boolean, default: false }) full!: boolean;

  @Prop({ required: false, type: Boolean, default: false }) popover!: boolean;

  @Prop({ required: false, type: Boolean, default: true }) limit!: boolean;

  usernameWithDomain = usernameWithDomain;

  displayName = displayName;
}
</script>
