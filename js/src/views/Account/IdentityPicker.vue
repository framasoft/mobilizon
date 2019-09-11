<template>
    <div class="identity-picker">
        <img class="image" v-if="currentIdentity.avatar" :src="currentIdentity.avatar.url"  :alt="currentIdentity.avatar.alt"/> {{ currentIdentity.name || `@${currentIdentity.preferredUsername}` }}
        <b-button type="is-text" @click="isComponentModalActive = true"><translate>Change</translate></b-button>
        <b-modal :active.sync="isComponentModalActive" has-modal-card>
            <div class="modal-card">
                <header class="modal-card-head">
                    <p class="modal-card-title">Pick an identity</p>
                </header>
                <section class="modal-card-body">
                    <div class="list is-hoverable">
                        <a class="list-item" v-for="identity in identities" :class="{ 'is-active': identity.id === currentIdentity.id }" @click="changeCurrentIdentity(identity)">
                            <div class="media">
                                <img class="media-left image" v-if="identity.avatar" :src="identity.avatar.url" />
                                <div class="media-content">
                                    <h3>@{{ identity.preferredUsername }}</h3>
                                    <small>{{ identity.name }}</small>
                                </div>
                            </div>
                        </a>
                    </div>
                </section>
            </div>
        </b-modal>
    </div>
</template>
<script lang="ts">
import { Component, Prop, Vue } from 'vue-property-decorator';
import { IActor } from '@/types/actor';
import { IDENTITIES } from '@/graphql/actor';

@Component({
  apollo: {
    identities: {
      query: IDENTITIES,
    },
  },
})
export default class IdentityPicker extends Vue {
  @Prop() value!: IActor;
  isComponentModalActive: boolean = false;
  identities: IActor[] = [];
  currentIdentity: IActor = this.value;

  changeCurrentIdentity(identity: IActor) {
    this.currentIdentity = identity;
    this.$emit('input', identity);
    this.isComponentModalActive = false;
  }

}
</script>
<style lang="scss">
    .identity-picker img.image {
        display: inline;
        height: 1.5em;
        vertical-align: text-bottom;
    }
</style>