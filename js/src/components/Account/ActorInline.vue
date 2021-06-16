<template>
  <div class="actor-inline">
    <div class="actor-avatar">
      <figure class="image is-24x24" v-if="actor.avatar">
        <img class="is-rounded" :src="actor.avatar.url" alt="" />
      </figure>
      <b-icon v-else size="is-medium" icon="account-circle" />
    </div>

    <div class="actor-name">
      <p>
        {{ actor.name || `@${usernameWithDomain(actor)}` }}
      </p>
    </div>
  </div>
</template>
<script lang="ts">
import { Component, Vue, Prop } from "vue-property-decorator";
import { IActor, usernameWithDomain } from "../../types/actor";

@Component
export default class ActorInline extends Vue {
  @Prop({ required: true, type: Object }) actor!: IActor;

  usernameWithDomain = usernameWithDomain;
}
</script>
<style lang="scss" scoped>
div.actor-inline {
  align-items: flex-start;
  display: inline-flex;
  text-align: inherit;
  align-items: top;

  div.actor-avatar {
    flex-basis: auto;
    flex-grow: 0;
    flex-shrink: 0;
    margin-right: 0.5rem;
  }
  div.actor-name {
    flex-basis: auto;
    flex-grow: 1;
    flex-shrink: 1;
    text-align: inherit;
  }
}
</style>
