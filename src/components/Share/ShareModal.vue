<template>
  <div class="dark:text-white p-4">
    <header class="">
      <h2 class="text-2xl">{{ title }}</h2>
    </header>

    <section class="flex">
      <div class="w-full">
        <slot></slot>
        <o-field :label="inputLabel" label-for="url-text">
          <o-input id="url-text" ref="URLInput" :modelValue="url" expanded />
          <p class="control">
            <o-tooltip
              :label="t('URL copied to clipboard')"
              :active="showCopiedTooltip"
              variant="success"
              position="left"
            />
            <o-button
              variant="primary"
              icon-right="content-paste"
              native-type="button"
              @click="copyURL"
              @keyup.enter="copyURL"
              :title="t('Copy URL to clipboard')"
            />
          </p>
        </o-field>
        <div class="flex flex-wrap gap-1">
          <a
            :href="twitterShare"
            target="_blank"
            rel="nofollow noopener"
            title="Twitter"
            ><Twitter :size="48" class="dark:text-white"
          /></a>
          <a
            :href="mastodonShare"
            class="mastodon"
            target="_blank"
            rel="nofollow noopener"
            title="Mastodon"
          >
            <mastodon-logo />
          </a>
          <a
            :href="facebookShare"
            target="_blank"
            rel="nofollow noopener"
            title="Facebook"
            ><Facebook :size="48" class="dark:text-white"
          /></a>
          <a
            :href="whatsAppShare"
            target="_blank"
            rel="nofollow noopener"
            title="WhatsApp"
            ><Whatsapp :size="48" class="dark:text-white"
          /></a>
          <a
            :href="telegramShare"
            class="telegram"
            target="_blank"
            rel="nofollow noopener"
            title="Telegram"
          >
            <telegram-logo />
          </a>
          <a
            :href="linkedInShare"
            target="_blank"
            rel="nofollow noopener"
            title="LinkedIn"
            ><LinkedIn :size="48" class="dark:text-white"
          /></a>
          <a
            :href="diasporaShare"
            class="diaspora"
            target="_blank"
            rel="nofollow noopener"
            title="Diaspora"
          >
            <diaspora-logo />
          </a>
          <a
            :href="emailShare"
            target="_blank"
            rel="nofollow noopener"
            title="Email"
          >
            <Email :size="48" class="dark:text-white" />
          </a>
        </div>
      </div>
    </section>
  </div>
</template>

<script lang="ts" setup>
import { computed, ref } from "vue";
import DiasporaLogo from "./DiasporaLogo.vue";
import MastodonLogo from "./MastodonLogo.vue";
import TelegramLogo from "./TelegramLogo.vue";
import Email from "vue-material-design-icons/Email.vue";
import LinkedIn from "vue-material-design-icons/Linkedin.vue";
import Whatsapp from "vue-material-design-icons/Whatsapp.vue";
import Facebook from "vue-material-design-icons/Facebook.vue";
import Twitter from "vue-material-design-icons/Twitter.vue";
import {
  diasporaShareUrl,
  emailShareUrl,
  facebookShareUrl,
  linkedInShareUrl,
  mastodonShareUrl,
  telegramShareUrl,
  twitterShareUrl,
  whatsAppShareUrl,
} from "@/utils/share";
import { useI18n } from "vue-i18n";

const props = withDefaults(
  defineProps<{
    title: string;
    url: string;
    text: string;
    inputLabel: string;
  }>(),
  {}
);

const { t } = useI18n({ useScope: "global" });

const URLInput = ref<{ $refs: { inputRef: HTMLInputElement } } | null>(null);

const showCopiedTooltip = ref(false);

const twitterShare = computed((): string | undefined =>
  twitterShareUrl(props.url, props.text)
);
const facebookShare = computed((): string | undefined =>
  facebookShareUrl(props.url)
);
const linkedInShare = computed((): string | undefined =>
  linkedInShareUrl(props.url, props.text)
);
const whatsAppShare = computed((): string | undefined =>
  whatsAppShareUrl(props.url, props.text)
);
const telegramShare = computed((): string | undefined =>
  telegramShareUrl(props.url, props.text)
);
const emailShare = computed((): string | undefined =>
  emailShareUrl(props.url, props.text)
);
const diasporaShare = computed((): string | undefined =>
  diasporaShareUrl(props.url, props.text)
);
const mastodonShare = computed((): string | undefined =>
  mastodonShareUrl(props.url, props.text)
);

const copyURL = (): void => {
  URLInput.value?.$refs.inputRef.select();
  document.execCommand("copy");
  showCopiedTooltip.value = true;
  setTimeout(() => {
    showCopiedTooltip.value = false;
  }, 2000);
};
</script>
<style lang="scss" scoped>
.diaspora,
.mastodon,
.telegram {
  :deep(span svg) {
    width: 2.5rem;
    margin-top: 5px;
  }
}
</style>
