<template>
    <section class="section container">
        <h1 class="title">{{ $t('Administration') }}</h1>
        <div class="tile is-ancestor" v-if="dashboard">
            <div class="tile is-vertical is-4">
                <div class="tile">
                    <div class="tile is-parent is-vertical is-6">
                        <article class="tile is-child box">
                            <p class="title">{{ dashboard.numberOfEvents }}</p>
                            <p>{{ $t('Published events')}}</p>
                        </article>
                        <article class="tile is-child box">
                            <p class="title">{{ dashboard.numberOfComments}}</p>
                            <p>{{ $t('Comments')}}</p>
                        </article>
                    </div>
                    <div class="tile is-parent is-vertical">
                        <article class="tile is-child box">
                            <p class="title">{{ dashboard.numberOfUsers }}</p>
                            <p>{{ $t('Users')}}</p>
                        </article>
                        <router-link :to="{ name: RouteName.REPORTS}">
                            <article class="tile is-child box">
                                <p class="title">{{ dashboard.numberOfReports }}</p>
                                <p>{{ $t('Opened reports')}}</p>
                            </article>
                        </router-link>
                    </div>
                </div>
                <div class="tile is-parent" v-if="dashboard.lastPublicEventPublished">
                    <router-link :to="{ name: RouteName.EVENT, params: { uuid: dashboard.lastPublicEventPublished.uuid } }">
                        <article class="tile is-child box">
                            <p class="title">{{ $t('Last published event') }}</p>
                            <p class="subtitle">{{ dashboard.lastPublicEventPublished.title }}</p>
                            <figure class="image is-4by3" v-if="dashboard.lastPublicEventPublished.picture">
                                <img :src="dashboard.lastPublicEventPublished.picture.url" />
                            </figure>
                        </article>
                    </router-link>
                </div>
                <div class="tile is-parent">
                    <router-link :to="{ name: RouteName.RELAYS }">
                        <article class="tile is-child box">
                            <span>{{ $t('Instances') }}</span>
                        </article>
                    </router-link>
                </div>
                <div class="tile is-parent">
                    <router-link :to="{ name: RouteName.ADMIN_SETTINGS }">
                        <article class="tile is-child box">
                            <span>{{ $t('Settings') }}</span>
                        </article>
                    </router-link>
                </div>
            </div>
            <div class="tile is-parent">
                <article class="tile is-child box">
                    <div class="content">
                        <p class="title">{{ $t('Welcome on your administration panel') }}</p>
                        <p class="subtitle">With even more content</p>
                        <div class="content">
                            <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Etiam semper diam at erat pulvinar, at pulvinar felis blandit. Vestibulum volutpat tellus diam, consequat gravida libero rhoncus ut. Morbi maximus, leo sit amet vehicula eleifend, nunc dui porta orci, quis semper odio felis ut quam.</p>
                            <p>Suspendisse varius ligula in molestie lacinia. Maecenas varius eget ligula a sagittis. Pellentesque interdum, nisl nec interdum maximus, augue diam porttitor lorem, et sollicitudin felis neque sit amet erat. Maecenas imperdiet felis nisi, fringilla luctus felis hendrerit sit amet. Aenean vitae gravida diam, finibus dignissim turpis. Sed eget varius ligula, at volutpat tortor.</p>
                            <p>Integer sollicitudin, tortor a mattis commodo, velit urna rhoncus erat, vitae congue lectus dolor consequat libero. Donec leo ligula, maximus et pellentesque sed, gravida a metus. Cras ullamcorper a nunc ac porta. Aliquam ut aliquet lacus, quis faucibus libero. Quisque non semper leo.</p>
                        </div>
                    </div>
                </article>
            </div>
        </div>
    </section>
</template>
<script lang="ts">
import { Component, Vue } from 'vue-property-decorator';
import { DASHBOARD } from '@/graphql/admin';
import { IDashboard } from '@/types/admin.model';
import { RouteName } from '@/router';

@Component({
  apollo: {
    dashboard: {
      query: DASHBOARD,
    },
  },
  metaInfo() {
    return {
      title: this.$t('Administration') as string,
      titleTemplate: '%s | Mobilizon',
    };
  },
})
export default class Dashboard extends Vue {
  dashboard!: IDashboard;
  RouteName = RouteName;
}
</script>