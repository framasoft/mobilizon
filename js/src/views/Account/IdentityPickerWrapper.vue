<template>
    <div class="identity-picker">
        <span v-if="inline" class="inline">
            <img class="image" v-if="currentIdentity.avatar" :src="currentIdentity.avatar.url"  :alt="currentIdentity.avatar.alt"/> {{ currentIdentity.name || `@${currentIdentity.preferredUsername}` }}
            <b-button type="is-text" @click="isComponentModalActive = true">
                {{ $t('Change') }}
            </b-button>
        </span>
        <span v-else class="block" @click="isComponentModalActive = true">
            <img class="image is-48x48" v-if="currentIdentity.avatar" :src="currentIdentity.avatar.url"  :alt="currentIdentity.avatar.alt"/>
            <b-icon v-else size="is-large" icon="account-circle" />
        </span>
        <b-modal :active.sync="isComponentModalActive" has-modal-card>
            <identity-picker v-model="currentIdentity" @input="relay" />
        </b-modal>
    </div>
</template>
<script lang="ts">
import { Component, Prop, Vue, Watch } from 'vue-property-decorator';
import { IActor } from '@/types/actor';
import IdentityPicker from './IdentityPicker.vue';

@Component({
  components: { IdentityPicker },
})
export default class IdentityPickerWrapper extends Vue {
  @Prop() value!: IActor;
  @Prop({ default: true, type: Boolean }) inline!: boolean;
  isComponentModalActive: boolean = false;
  currentIdentity: IActor = this.value;

  @Watch('value')
    updateCurrentActor(value) {
    this.currentIdentity = value;
  }

  relay(identity: IActor) {
    this.currentIdentity = identity;
    this.$emit('input', identity);
    this.isComponentModalActive = false;
  }

}
</script>
<style lang="scss">
    .identity-picker {

        .block {
            cursor: pointer;
        }

        .inline img.image {
            display: inline;
            height: 1.5em;
            vertical-align: text-bottom;
        }
    }
</style>
