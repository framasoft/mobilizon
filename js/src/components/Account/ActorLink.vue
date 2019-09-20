<template>
    <span>
        <span v-if="actor.domain === null"
                     :to="{name: 'Profile', params: { name: actor.preferredUsername } }"
        >
            <slot></slot>
        </span>
        <a v-else :href="actor.url">
            <slot></slot>
        </a>
    </span>
</template>
<script lang="ts">
import { Component, Prop, Vue } from 'vue-property-decorator';
import { IActor } from '@/types/actor';

@Component
export default class ActorLink extends Vue {
  @Prop() actor!: IActor;
}
</script>