<template>
  <div class="inline-flex items-start">
    <div class="flex-none mr-2">
      <figure class="image is-48x48" v-if="actor.avatar">
        <img class="is-rounded" :src="actor.avatar.url" alt="" />
      </figure>
      <b-icon v-else size="is-large" icon="account-circle" />
    </div>

    <div class="flex-auto">
      <p class="text-base line-clamp-3 md:line-clamp-2 max-w-xl">
        {{ displayName(actor) }}
      </p>
      <p class="text-sm text-gray-500 truncate">
        @{{ usernameWithDomain(actor) }}
      </p>
    </div>
  </div>
</template>
<script lang="ts">
import { Component, Vue, Prop } from "vue-property-decorator";
import { displayName, IActor, usernameWithDomain } from "../../types/actor";

@Component
export default class ActorInline extends Vue {
  @Prop({ required: true, type: Object }) actor!: IActor;

  usernameWithDomain = usernameWithDomain;

  displayName = displayName;
}
</script>
<style lang="scss" scoped>
@use "@/styles/_mixins" as *;
div.actor-inline {
  align-items: flex-start;
  display: inline-flex;
  text-align: inherit;
  align-items: top;

  div.actor-avatar {
    flex-basis: auto;
    flex-grow: 0;
    flex-shrink: 0;
    @include margin-right(0.5rem);
  }
  div.actor-name {
    flex-basis: auto;
    flex-grow: 1;
    flex-shrink: 1;
    text-align: inherit;
  }
}
</style>
