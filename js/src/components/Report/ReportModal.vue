<template>
        <div class="modal-card">
            <header class="modal-card-head" v-if="title">
                <p class="modal-card-title">{{ title }}</p>
            </header>

            <section
                    class="modal-card-body is-flex"
                    :class="{ 'is-titleless': !title }">
                <div class="media">
                    <div
                            class="media-left">
                        <b-icon
                                icon="alert"
                                type="is-warning"
                                size="is-large"/>
                    </div>
                    <div class="media-content">
                        <div class="box" v-if="comment">
                            <article class="media">
                                <div class="media-left">
                                    <figure class="image is-48x48" v-if="comment.actor.avatar">
                                        <img :src="comment.actor.avatar.url" alt="Image">
                                    </figure>
                                    <b-icon class="media-left" v-else size="is-large" icon="account-circle" />
                                </div>
                                <div class="media-content">
                                    <div class="content">
                                        <strong>{{ comment.actor.name }}</strong> <small>@{{ comment.actor.preferredUsername }}</small>
                                        <br>
                                        <p v-html="comment.text"></p>
                                    </div>
                                </div>
                            </article>
                        </div>
                        <p>{{ $t('The report will be sent to the moderators of your instance. You can explain why you report this content below.') }}</p>

                        <div class="control">
                            <b-input
                                    v-model="content"
                                    type="textarea"
                                    @keyup.enter="confirm"
                                    :placeholder="$t('Additional comments')"
                            />
                        </div>

                        <p v-if="outsideDomain">
                            {{ $t('The content came from another server. Transfer an anonymous copy of the report?') }}
                        </p>

                        <div class="control" v-if="outsideDomain">
                            <b-switch v-model="forward">{{ $t('Transfer to {outsideDomain}', { outsideDomain }) }}</b-switch>
                        </div>
                    </div>
                </div>
            </section>

            <footer class="modal-card-foot">
                <button
                        class="button"
                        ref="cancelButton"
                        @click="close">
                    {{ translatedCancelText }}
                </button>
                <button
                        class="button is-primary"
                        ref="confirmButton"
                        @click="confirm">
                    {{ translatedConfirmText }}
                </button>
            </footer>
        </div>
</template>

<script lang="ts">
import { Component, Prop, Vue } from 'vue-property-decorator';
import { IComment } from '@/types/comment.model';

@Component({
  mounted() {
    this.$data.isActive = true;
  },
})
export default class ReportModal extends Vue {
  @Prop({ type: Function, default: () => {} }) onConfirm;
  @Prop({ type: String }) title;
  @Prop({ type: Object }) comment!: IComment;
  @Prop({ type: String, default: '' }) outsideDomain;
  @Prop({ type: String }) cancelText;
  @Prop({ type: String }) confirmText;

  isActive: boolean = false;
  content: string = '';
  forward: boolean = false;

  get translatedCancelText() {
    return this.cancelText || this.$t('Cancel');
  }

  get translatedConfirmText() {
    return this.confirmText || this.$t('Send the report');
  }

  confirm() {
    this.onConfirm(this.content, this.forward);
    this.close();
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
<style lang="scss" scoped>
    .modal-card .modal-card-foot {
        justify-content: flex-end;
    }

    .modal-card-body {
        .media-content {
            .box {
                .media {
                    padding-top: 0;
                    border-top: none;
                }
            }

            & > p {
                margin-bottom: 2rem;
            }
        }
    }
</style>
