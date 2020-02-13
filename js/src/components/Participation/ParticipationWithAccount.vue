<template>
    <section class="section container hero is-fullheight">
        <div class="hero-body">
            <div class="container">
                <div class="columns">
                    <div class="column">
                        <b-button type="is-primary" size="is-medium" tag="router-link" :to="{ name: RouteName.LOGIN }">{{ $t('Login on {instance}', { instance: host }) }}</b-button>
                    </div>
                    <vertical-divider :content="$t('Or')" />
                    <div class="column">
                        <h3 class="subtitle">{{ $t('I have an account on another Mobilizon instance.')}}</h3>
                        <p>{{ $t('Other software may also support this.') }}</p>
                        <p>{{ $t('We will redirect you to your instance in order to interact with this event') }}</p>
                        <form @submit.prevent="redirectToInstance">
                            <b-field :label="$t('Your federated identity')">
                            <b-field>
                                <b-input
                                        expanded
                                        autocapitalize="none" autocorrect="off"
                                        v-model="remoteActorAddress"
                                        :placeholder="$t('profile@instance')">
                                </b-input>
                                <p class="control">
                                    <button class="button is-primary" type="submit">{{ $t('Go') }}</button>
                                </p>
                            </b-field>
                            </b-field>
                        </form>
                    </div>
                </div>
                <div class="has-text-centered">
                    <b-button tag="a" type="is-text" @click="$router.go(-1)">
                        {{ $t('Back to previous page') }}
                    </b-button>
                </div>
            </div>
        </div>
    </section>
</template>
<script lang="ts">
import { Component, Prop, Vue } from 'vue-property-decorator';
import { RouteName } from '@/router';
import VerticalDivider from '@/components/Utils/VerticalDivider.vue';

@Component({
  components: { VerticalDivider },
})
export default class ParticipationWithAccount extends Vue {
  @Prop({ type: String, required: true }) uuid!: string;
  remoteActorAddress: string = '';
  RouteName = RouteName;

  get host() {
    return window.location.hostname;
  }

  get uri(): string {
    return `${window.location.origin}${this.$router.resolve({ name: RouteName.EVENT, params: { uuid: this.uuid } }).href}`;
  }

  async redirectToInstance() {
    let res;
    const [_, host] = res = this.remoteActorAddress.split('@', 2);
    const remoteInteractionURI = await this.webFingerFetch(host, this.remoteActorAddress);
    window.open(remoteInteractionURI);
  }

  private async webFingerFetch(hostname: string, identity: string): Promise<string> {
    const scheme = process.env.NODE_ENV === 'production' ? 'https' : 'http';
    const data = await ((await fetch(`${scheme}://${hostname}/.well-known/webfinger?resource=acct:${identity}`)).json());
    if (data && Array.isArray(data.links)) {
      const link: { template: string } = data.links.find((link: any) => {
        return link && typeof link.template === 'string' && link.rel === 'http://ostatus.org/schema/1.0/subscribe';
      });

      if (link && link.template.includes('{uri}')) {
        return link.template.replace('{uri}', encodeURIComponent(this.uri));
      }
    }
    throw new Error('No interaction path found in webfinger data');
  }
}
</script>