<template>
  <section class="section container hero is-fullheight">
    <div class="hero-body">
      <div class="container">
        <div class="columns is-vcentered">
          <div class="column has-text-centered">
            <b-button
              type="is-primary"
              size="is-medium"
              tag="router-link"
              :to="{
                name: RouteName.LOGIN,
                query: {
                  code: LoginErrorCode.NEED_TO_LOGIN,
                  redirect: pathAfterLogin,
                },
              }"
              >{{ $t("Login on {instance}", { instance: host }) }}</b-button
            >
          </div>
          <vertical-divider :content="$t('Or')" />
          <div class="column">
            <subtitle>{{
              $t("I have an account on another Mobilizon instance.")
            }}</subtitle>
            <p>{{ $t("Other software may also support this.") }}</p>
            <p>{{ sentence }}</p>
            <form @submit.prevent="redirectToInstance">
              <b-field :label="$t('Your federated identity')">
                <b-field>
                  <b-input
                    expanded
                    autocapitalize="none"
                    autocorrect="off"
                    v-model="remoteActorAddress"
                    :placeholder="$t('profile@instance')"
                  ></b-input>
                  <p class="control">
                    <button class="button is-primary" type="submit">
                      {{ $t("Go") }}
                    </button>
                  </p>
                </b-field>
              </b-field>
            </form>
          </div>
        </div>
        <div class="has-text-centered">
          <b-button tag="a" type="is-text" @click="$router.go(-1)">{{
            $t("Back to previous page")
          }}</b-button>
        </div>
      </div>
    </div>
  </section>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import VerticalDivider from "@/components/Utils/VerticalDivider.vue";
import Subtitle from "@/components/Utils/Subtitle.vue";
import { LoginErrorCode } from "@/types/enums";
import RouteName from "../../router/name";

@Component({
  components: { Subtitle, VerticalDivider },
})
export default class RedirectWithAccount extends Vue {
  @Prop({ type: String, required: true }) uri!: string;

  @Prop({ type: String, required: false }) pathAfterLogin!: string;

  @Prop({ type: String, required: false }) sentence!: string;

  remoteActorAddress = "";

  RouteName = RouteName;

  LoginErrorCode = LoginErrorCode;

  // eslint-disable-next-line class-methods-use-this
  get host(): string {
    return window.location.hostname;
  }

  async redirectToInstance(): Promise<void> {
    const [, host] = this.remoteActorAddress.split("@", 2);
    const remoteInteractionURI = await this.webFingerFetch(
      host,
      this.remoteActorAddress
    );
    window.open(remoteInteractionURI);
  }

  private async webFingerFetch(
    hostname: string,
    identity: string
  ): Promise<string> {
    const scheme = process.env.NODE_ENV === "production" ? "https" : "http";
    const data = await (
      await fetch(
        `${scheme}://${hostname}/.well-known/webfinger?resource=acct:${identity}`
      )
    ).json();
    if (data && Array.isArray(data.links)) {
      const link: { template: string } = data.links.find(
        (someLink: any) =>
          someLink &&
          typeof someLink.template === "string" &&
          someLink.rel === "http://ostatus.org/schema/1.0/subscribe"
      );

      if (link && link.template.includes("{uri}")) {
        return link.template.replace("{uri}", encodeURIComponent(this.uri));
      }
    }
    throw new Error("No interaction path found in webfinger data");
  }
}
</script>
