<template>
  <div class="identity-picker">
    <div
      v-if="inline"
      class="inline box"
      :class="{ 'has-background-grey-lighter': masked }"
      @click="isComponentModalActive = true"
    >
      <div class="media">
        <div class="media-left">
          <figure class="image is-48x48" v-if="currentIdentity.avatar">
            <img class="image is-rounded" :src="currentIdentity.avatar.url" alt="" />
          </figure>
          <b-icon v-else size="is-large" icon="account-circle" />
        </div>
        <div class="media-content" v-if="currentIdentity.name">
          <p class="is-4">{{ currentIdentity.name }}</p>
          <p class="is-6 has-text-grey">
            {{ `@${currentIdentity.preferredUsername}` }}
            <span v-if="masked">{{ $t("(Masked)") }}</span>
          </p>
        </div>
        <div class="media-content" v-else>
          {{ `@${currentIdentity.preferredUsername}` }}
        </div>
        <b-button type="is-text" @click="isComponentModalActive = true">
          {{ $t("Change") }}
        </b-button>
      </div>
    </div>
    <span v-else class="block" @click="isComponentModalActive = true">
      <figure class="image is-48x48" v-if="currentIdentity.avatar">
        <img class="is-rounded" :src="currentIdentity.avatar.url" alt="" />
      </figure>
      <b-icon v-else size="is-large" icon="account-circle" />
    </span>
    <b-modal :active.sync="isComponentModalActive" has-modal-card>
      <identity-picker v-model="currentIdentity" @input="relay" />
    </b-modal>
  </div>
</template>
<script lang="ts">
import { Component, Prop, Vue, Watch } from "vue-property-decorator";
import { IActor } from "../../types/actor";
import IdentityPicker from "./IdentityPicker.vue";

@Component({
  components: { IdentityPicker },
})
export default class IdentityPickerWrapper extends Vue {
  @Prop() value!: IActor;

  @Prop({ default: true, type: Boolean }) inline!: boolean;

  @Prop({ type: Boolean, required: false, default: false }) masked = false;

  isComponentModalActive = false;

  currentIdentity: IActor = this.value;

  @Watch("value")
  updateCurrentActor(value: IActor) {
    this.currentIdentity = value;
  }

  relay(identity: IActor) {
    this.currentIdentity = identity;
    this.$emit("input", identity);
    this.isComponentModalActive = false;
  }
}
</script>
<style lang="scss">
.identity-picker {
  .block {
    cursor: pointer;
  }

  .inline {
    cursor: pointer;
  }
}
</style>
