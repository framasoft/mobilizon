<template>
  <div class="modal-card">
    <header class="modal-card-head">
      <p class="modal-card-title">{{ $t("Share this event") }}</p>
    </header>

    <section class="modal-card-body is-flex" v-if="event">
      <div class="container has-text-centered">
        <small class="maximumNumberOfPlacesWarning" v-if="!eventCapacityOK">
          {{ $t("All the places have already been taken") }}
        </small>
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
          <a :href="diasporaShareUrl" class="diaspora" target="_blank" rel="nofollow noopener">
            <span data-v-5e15e80a="" class="icon has-text-primary is-large">
              <DiasporaLogo alt="diaspora-logo" />
            </span>
          </a>
          <a :href="emailShareUrl" target="_blank" rel="nofollow noopener"
            ><b-icon icon="email" size="is-large" type="is-primary"
          /></a>
          <!--     TODO: mailto: links are not used anymore, we should provide a popup to redact a message instead    -->
        </div>
      </div>
    </section>
  </div>
</template>

<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { IEvent } from "../../types/event.model";
// @ts-ignore
import DiasporaLogo from "../../assets/diaspora-icon.svg?inline";

@Component({
  components: {
    DiasporaLogo,
  },
})
export default class ShareEventModal extends Vue {
  @Prop({ type: Object, required: true }) event!: IEvent;
  @Prop({ type: Boolean, required: false, default: true }) eventCapacityOK!: boolean;
  get twitterShareUrl(): string {
    return `https://twitter.com/intent/tweet?url=${encodeURIComponent(this.event.url)}&text=${
      this.event.title
    }`;
  }

  get facebookShareUrl(): string {
    return `https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(this.event.url)}`;
  }

  get linkedInShareUrl(): string {
    return `https://www.linkedin.com/shareArticle?mini=true&url=${encodeURIComponent(
      this.event.url
    )}&title=${this.event.title}`;
  }

  get emailShareUrl(): string {
    return `mailto:?to=&body=${this.event.url}${encodeURIComponent(
      "\n\n"
      // @ts-ignore
    )}${ShareEventModal.textDescription}&subject=${this.event.title}`;
  }

  get diasporaShareUrl(): string {
    return `https://share.diasporafoundation.org/?title=${encodeURIComponent(
      this.event.title
    )}&url=${encodeURIComponent(this.event.url)}`;
  }

  static get textDescription(): string {
    const meta = document.querySelector("meta[property='og:description']");
    if (!meta) return "";
    const desc = meta.getAttribute("content") || "";
    return desc.substring(0, 1000);
  }
}
</script>
<style lang="scss" scoped>
.diaspora span svg {
  height: 2rem;
  width: 2rem;
}
</style>
