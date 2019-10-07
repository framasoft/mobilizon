<docs>
A simple link to an actor, local or remote link

```vue
<template>
    <ActorLink :actor="localActor">
        <template>
            <span>{{ localActor.preferredUsername }}</span>
        </template>
    </ActorLink>
</template>
<script>
export default {
    data() {
        return {
            localActor: {
                domain: null,
                preferredUsername: 'localActor'
            },
        }
    }
}
</script>
```

```vue
<template>
    <ActorLink :actor="remoteActor">
        <template>
            <span>{{ remoteActor.preferredUsername }}</span>
        </template>
    </ActorLink>
</template>
<script>
export default {
    data() {
        return {
            remoteActor: {
                domain: 'mobilizon.org',
                url: 'https://mobilizon.org/@Framasoft',
                preferredUsername: 'Framasoft'
            },
        }
    }
}
</script>
```

</docs>

<template>
    <span>
        <span v-if="actor.domain === null"
                     :to="{name: 'Profile', params: { name: actor.preferredUsername } }"
        >
            <!-- @slot What to put inside the link -->
            <slot></slot>
        </span>
        <a v-else :href="actor.url">
            <!-- @slot What to put inside the link -->
            <slot></slot>
        </a>
    </span>
</template>
<script lang="ts">
import { Component, Prop, Vue } from 'vue-property-decorator';
import { IActor } from '@/types/actor';

@Component
export default class ActorLink extends Vue {
  /**
   * The actor you want to make a link to
   */
  @Prop({ required: true }) actor!: IActor;
}
</script>