<template>
  <div class="modal-card">
    <header class="modal-card-head">
      <p class="modal-card-title">{{ $t("Share this post") }}</p>
    </header>

    <section class="modal-card-body is-flex" v-if="post">
      <div class="container has-text-centered">
        <b-notification
          type="is-warning"
          v-if="post.visibility !== PostVisibility.PUBLIC"
          :closable="false"
        >
          {{
            $t(
              "This post is accessible only through it's link. Be careful where you post this link."
            )
          }}
        </b-notification>
        <b-field :label="$t('Post URL')" label-for="post-url-text">
          <b-input
            id="post-url-text"
            ref="postURLInput"
            :value="postURL"
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
            class="telegram"
            target="_blank"
            rel="nofollow noopener"
            title="Telegram"
          >
            <telegram-logo />
          </a>
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
import { PostVisibility } from "@/types/enums";
import { IPost } from "../../types/post.model";
import DiasporaLogo from "../Share/DiasporaLogo.vue";
import MastodonLogo from "../Share/MastodonLogo.vue";
import TelegramLogo from "../Share/TelegramLogo.vue";
import { PropType } from "vue";
import RouteName from "@/router/name";

@Component({
  components: {
    DiasporaLogo,
    MastodonLogo,
    TelegramLogo,
  },
})
export default class SharePostModal extends Vue {
  @Prop({ type: Object as PropType<IPost>, required: true }) post!: IPost;

  @Ref("postURLInput") readonly postURLInput!: any;

  PostVisibility = PostVisibility;

  RouteName = RouteName;

  showCopiedTooltip = false;

  get twitterShareUrl(): string {
    return `https://twitter.com/intent/tweet?url=${encodeURIComponent(
      this.postURL
    )}&text=${this.post.title}`;
  }

  get facebookShareUrl(): string {
    return `https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(
      this.postURL
    )}`;
  }

  get linkedInShareUrl(): string {
    return `https://www.linkedin.com/shareArticle?mini=true&url=${encodeURIComponent(
      this.postURL
    )}&title=${this.post.title}`;
  }

  get whatsAppShareUrl(): string {
    return `https://wa.me/?text=${encodeURIComponent(this.basicTextToEncode)}`;
  }

  get telegramShareUrl(): string {
    return `https://t.me/share/url?url=${encodeURIComponent(
      this.postURL
    )}&text=${encodeURIComponent(this.post.title)}`;
  }

  get emailShareUrl(): string {
    return `mailto:?to=&body=${this.postURL}&subject=${this.post.title}`;
  }

  get diasporaShareUrl(): string {
    return `https://share.diasporafoundation.org/?title=${encodeURIComponent(
      this.post.title
    )}&url=${encodeURIComponent(this.postURL)}`;
  }

  get mastodonShareUrl(): string {
    return `https://toot.karamoff.dev/?text=${encodeURIComponent(
      this.basicTextToEncode
    )}`;
  }

  get basicTextToEncode(): string {
    return `${this.post.title}\r\n${this.postURL}`;
  }

  get postURL(): string {
    if (this.post.id) {
      return this.$router.resolve({
        name: RouteName.POST,
        params: { id: this.post.id },
      }).href;
    }
    return "";
  }

  copyURL(): void {
    this.postURLInput.$refs.input.select();
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
.mastodon,
.telegram {
  ::v-deep span svg {
    width: 2.25rem;
  }
}
</style>
