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
        <b-field :label="$t('Event URL')" label-for="event-url-text">
          <b-input
            id="event-url-text"
            ref="eventURLInput"
            :value="event.url"
            expanded
          />
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
                :title="$t('Copy URL to clipboard')"
              />
            </b-tooltip>
          </p>
        </b-field>
        <div>
          <a
            :href="twitterShareUrl"
            target="_blank"
            rel="nofollow noopener"
            title="Twitter"
            ><b-icon icon="twitter" size="is-large" type="is-primary"
          /></a>
          <a
            :href="mastodonShareUrl"
            class="mastodon"
            target="_blank"
            rel="nofollow noopener"
            title="Mastodon"
          >
            <mastodon-logo />
          </a>
          <a
            :href="facebookShareUrl"
            target="_blank"
            rel="nofollow noopener"
            title="Facebook"
            ><b-icon icon="facebook" size="is-large" type="is-primary"
          /></a>
          <a
            :href="whatsAppShareUrl"
            target="_blank"
            rel="nofollow noopener"
            title="WhatsApp"
            ><b-icon icon="whatsapp" size="is-large" type="is-primary"
          /></a>
          <a
            :href="telegramShareUrl"
            target="_blank"
            rel="nofollow noopener"
            title="Telegram"
            ><b-icon icon="telegram" size="is-large" type="is-primary"
          /></a>
          <a
            :href="linkedInShareUrl"
            target="_blank"
            rel="nofollow noopener"
            title="LinkedIn"
            ><b-icon icon="linkedin" size="is-large" type="is-primary"
          /></a>
          <a
            :href="diasporaShareUrl"
            class="diaspora"
            target="_blank"
            rel="nofollow noopener"
            title="Diaspora"
          >
            <diaspora-logo />
          </a>
          <a
            :href="emailShareUrl"
            target="_blank"
            rel="nofollow noopener"
            title="Email"
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
import DiasporaLogo from "../Share/DiasporaLogo.vue";
import MastodonLogo from "../Share/MastodonLogo.vue";

@Component({
  components: {
    DiasporaLogo,
    MastodonLogo,
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

  get whatsAppShareUrl(): string {
    return `https://wa.me/?text=${encodeURIComponent(this.basicTextToEncode)}`;
  }

  get telegramShareUrl(): string {
    return `https://t.me/share/url?url=${encodeURIComponent(
      this.event.url
    )}&text=${encodeURIComponent(this.event.title)}`;
  }

  get emailShareUrl(): string {
    return `mailto:?to=&body=${this.event.url}&subject=${this.event.title}`;
  }

  get diasporaShareUrl(): string {
    return `https://share.diasporafoundation.org/?title=${encodeURIComponent(
      this.event.title
    )}&url=${encodeURIComponent(this.event.url)}`;
  }

  get mastodonShareUrl(): string {
    return `https://toot.karamoff.dev/?text=${encodeURIComponent(
      this.basicTextToEncode
    )}`;
  }

  get basicTextToEncode(): string {
    return `${this.event.title}\r\n${this.event.url}`;
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
.diaspora,
.mastodon {
  ::v-deep span svg {
    width: 2.25rem;
  }
}
</style>
