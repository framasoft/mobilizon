<template>
    <div class="modal-card">
        <header class="modal-card-head">
            <p class="modal-card-title">Join event {{ event.title }}</p>
        </header>

        <section class="modal-card-body is-flex">
            <div class="media">
                <div
                        class="media-left">
                    <b-icon
                            icon="alert"
                            type="is-warning"
                            size="is-large"/>
                </div>
                <div class="media-content">
                    <p>Do you want to participate in {{ event.title }}?</p>

                    <b-field :label="$t('Identity')">
                        <identity-picker v-model="identity"></identity-picker>
                    </b-field>

                    <p v-if="!event.local">
                        The event came from another instance. Your participation will be confirmed after we confirm it with the other instance.
                    </p>
                </div>
            </div>
        </section>

        <footer class="modal-card-foot">
            <button
                    class="button"
                    ref="cancelButton"
                    @click="close">
                Cancel
            </button>
            <button
                    class="button is-primary"
                    ref="confirmButton"
                    @click="confirm">
                Confirm my particpation
            </button>
        </footer>
    </div>
</template>

<script lang="ts">
import { Component, Prop, Vue } from 'vue-property-decorator';
import { IEvent } from '@/types/event.model';
import IdentityPicker from '@/views/Account/IdentityPicker.vue';
import { IPerson } from '@/types/actor';

@Component({
  components: {
    IdentityPicker,
  },
  mounted() {
    this.$data.isActive = true;
  },
})
export default class ReportModal extends Vue {
  @Prop({ type: Function, default: () => {} }) onConfirm;
  @Prop({ type: Object }) event! : IEvent;
  @Prop({ type: Object }) defaultIdentity!: IPerson;

  isActive: boolean = false;
  identity: IPerson = this.defaultIdentity;

  confirm() {
    this.onConfirm(this.identity);
  }

    /**
     * Close the Dialog.
     */
  close() {
    this.isActive = false;
    this.$emit('close');
  }
}
</script>
<style lang="scss">
    .modal-card .modal-card-foot {
        justify-content: flex-end;
    }
</style>