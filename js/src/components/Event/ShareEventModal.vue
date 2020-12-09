<template>
  <div class="modal-card">
    <header class="modal-card-head">
      <p class="modal-card-title">{{ $t("Share this event") }}</p>
    </header>

    <section class="modal-card-body is-flex" v-if="event">
      <div class="container has-text-centered">
        <b-notification
          type="is-warning"
          v-if="event.visibility !== EventVisibility.PUBLIC"
          :closable="false"
        >
          {{
            $t(
              "This event is accessible only through it's link. Be careful where you post this link."
            )
          }}
        </b-notification>
        <b-notification
          type="is-danger"
          v-if="event.status === EventStatus.CANCELLED"
          :closable="false"
        >
          {{ $t("This event has been cancelled.") }}
        </b-notification>
        <small class="maximumNumberOfPlacesWarning" v-if="!eventCapacityOK">
          {{ $t("All the places have already been taken") }}
        </small>
        <b-field>
          <b-input ref="eventURLInput" :value="event.url" expanded />
          <p class="control">
            <b-tooltip
              :label="$t('URL copied to clipboard')"
              :active="showCopiedTooltip"
              always
              type="is-success"
              position="is-left"
            >
              <b-button
                type="is-primary"
                icon-right="content-paste"
                native-type="button"
                @click="copyURL"
                @keyup.enter="copyURL"
              />
            </b-tooltip>
          </p>
        </b-field>
        <div>
          <!--                  <b-icon icon="mastodon" size="is-large" type="is-primary" />-->

          <a :href="twitterShareUrl" target="_blank" rel="nofollow noopener"
            ><b-icon icon="twitter" size="is-large" type="is-primary"
          /></a>
          <a :href="facebookShareUrl" target="_blank" rel="nofollow noopener"
            ><b-icon icon="facebook" size="is-large" type="is-primary"
          /></a>
          <a :href="linkedInShareUrl" target="_blank" rel="nofollow noopener"
            ><b-icon icon="linkedin" size="is-large" type="is-primary"
          /></a>
          <a
            :href="diasporaShareUrl"
            class="diaspora"
            target="_blank"
            rel="nofollow noopener"
          >
            <span data-v-5e15e80a="" class="icon has-text-primary is-large">
              <DiasporaLogo alt="diaspora-logo" />
            </span>
          </a>
          <a :href="emailShareUrl" target="_blank" rel="nofollow noopener"
            ><b-icon icon="email" size="is-large" type="is-primary"
          /></a>
        </div>
      </div>
    </section>
  </div>
</template>

<script lang="ts">
import { Component, Prop, Vue, Ref } from "vue-property-decorator";
import { EventStatus, EventVisibility } from "@/types/enums";
import { IEvent } from "../../types/event.model";
// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
import DiasporaLogo from "../../assets/diaspora-icon.svg?inline";

@Component({
  components: {
    DiasporaLogo,
  },
})
export default class ShareEventModal extends Vue {
  @Prop({ type: Object, required: true }) event!: IEvent;

  @Prop({ type: Boolean, required: false, default: true })
  eventCapacityOK!: boolean;

  @Ref("eventURLInput") readonly eventURLInput!: any;

  EventVisibility = EventVisibility;

  EventStatus = EventStatus;

  showCopiedTooltip = false;

  get twitterShareUrl(): string {
    return `https://twitter.com/intent/tweet?url=${encodeURIComponent(
      this.event.url
    )}&text=${this.event.title}`;
  }

  get facebookShareUrl(): string {
    return `https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(
      this.event.url
    )}`;
  }

  get linkedInShareUrl(): string {
    return `https://www.linkedin.com/shareArticle?mini=true&url=${encodeURIComponent(
      this.event.url
    )}&title=${this.event.title}`;
  }

  get emailShareUrl(): string {
    return `mailto:?to=&body=${this.event.url}&subject=${this.event.title}`;
  }

  get diasporaShareUrl(): string {
    return `https://share.diasporafoundation.org/?title=${encodeURIComponent(
      this.event.title
    )}&url=${encodeURIComponent(this.event.url)}`;
  }

  copyURL(): void {
    this.eventURLInput.$refs.input.select();
    document.execCommand("copy");
    this.showCopiedTooltip = true;
    setTimeout(() => {
      this.showCopiedTooltip = false;
    }, 2000);
  }
}
</script>
<style lang="scss" scoped>
.diaspora span svg {
  height: 2rem;
  width: 2rem;
}
</style>
