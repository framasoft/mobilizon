<template>
    <section class="container">
        <h1 class="title">Administration</h1>
        <div class="tile is-ancestor" v-if="dashboard">
            <div class="tile is-vertical is-4">
                <div class="tile">
                    <div class="tile is-parent is-vertical is-6">
                        <article class="tile is-child box">
                            <p class="title">{{ dashboard.numberOfEvents }}</p>
                            <p class="subtitle">événements publiés</p>
                        </article>
                        <article class="tile is-child box">
                            <p class="title">{{ dashboard.numberOfComments}}</p>
                            <p class="subtitle">commentaires</p>
                        </article>
                    </div>
                    <div class="tile is-parent is-vertical">
                        <article class="tile is-child box">
                            <p class="title">{{ dashboard.numberOfUsers }}</p>
                            <p class="subtitle">utilisateurices</p>
                        </article>
                        <router-link :to="{ name: ModerationRouteName.REPORTS}">
                            <article class="tile is-child box">
                                <p class="title">{{ dashboard.numberOfReports }}</p>
                                <p class="subtitle">signalements ouverts</p>
                            </article>
                        </router-link>
                    </div>
                </div>
                <div class="tile is-parent" v-if="dashboard.lastPublicEventPublished">
                    <article class="tile is-child box">
                        <p class="title">Dernier événement publié</p>
                        <p class="subtitle">{{ dashboard.lastPublicEventPublished.title }}</p>
                        <figure class="image is-4by3" v-if="dashboard.lastPublicEventPublished.picture">
                            <img :src="dashboard.lastPublicEventPublished.picture.url" />
                        </figure>
                    </article>
                </div>
            </div>
            <div class="tile is-parent">
                <article class="tile is-child box">
                    <div class="content">
                        <p class="title">Bienvenue sur votre espace d'administration</p>
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
import { ModerationRouteName } from '@/router/moderation';

@Component({
  apollo: {
    dashboard: {
      query: DASHBOARD,
    },
  },
})
export default class Dashboard extends Vue {
  dashboard!: IDashboard;
  ModerationRouteName = ModerationRouteName;
}
</script>