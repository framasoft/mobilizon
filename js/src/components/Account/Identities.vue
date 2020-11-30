<template>
  <section>
    <h1 class="title">
      {{ $t("My identities") }}
    </h1>

    <ul class="identities">
      <li v-for="identity in identities" :key="identity.id">
        <router-link
          :to="{
            name: 'UpdateIdentity',
            params: { identityName: identity.preferredUsername },
          }"
          class="media identity"
          v-bind:class="{ 'is-current-identity': isCurrentIdentity(identity) }"
        >
          <div class="media-left">
            <figure class="image is-48x48" v-if="identity.avatar">
              <img class="is-rounded" :src="identity.avatar.url" />
            </figure>
          </div>

          <div class="media-content">
            {{ identity.displayName() }}
          </div>
        </router-link>
      </li>
    </ul>

    <router-link
      :to="{ name: 'CreateIdentity' }"
      class="button create-identity is-primary"
    >
      {{ $t("Create a new identity") }}
    </router-link>
  </section>
</template>

<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { IDENTITIES } from "../../graphql/actor";
import { IPerson, Person } from "../../types/actor";

@Component({
  apollo: {
    identities: {
      query: IDENTITIES,

      update(result) {
        return result.identities.map((i: IPerson) => new Person(i));
      },
    },
  },
})
export default class Identities extends Vue {
  @Prop({ type: String }) currentIdentityName!: string;

  identities: Person[] = [];

  errors: string[] = [];

  isCurrentIdentity(identity: IPerson): boolean {
    return identity.preferredUsername === this.currentIdentityName;
  }
}
</script>

<style lang="scss" scoped>
.identities {
  border-right: 1px solid grey;

  padding: 15px 0;
}

.media.identity {
  align-items: center;
  font-size: 1.3rem;
  padding-bottom: 0;
  margin-bottom: 15px;
  color: #000;

  &.is-current-identity {
    background-color: rgba(0, 0, 0, 0.1);
  }
}

.title {
  margin-bottom: 30px;
}
</style>
