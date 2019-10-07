<template>
    <div>
        <div class="hero intro is-medium is-primary">
            <div class="hero-body">
                <div class="container">
                    <h1 class="title">{{ $t('About Mobilizon') }}</h1>
                    <p class="subtitle">
                        {{ $t('A user-friendly, emancipatory and ethical tool for gathering, organising, and mobilising.') }}
                    </p>
                    <b-button icon-left="open-in-new" size="is-large" type="is-secondary" tag="a" href="https://joinmobilizon.org">{{ $t('Learn more') }}</b-button>
                </div>
            </div>
        </div>
        <div class="container" id="mobilizon">
            <section>
                <div class="columns">
                    <div class="column has-text-left-desktop">
                        <h3 class="title">{{ $t('Gather ⋅ Organize ⋅ Mobilize') }}</h3>
                        <p class="content" v-html="$t('From a birthday party with friends and family to a march for climate change, right now, our gatherings are <b>trapped inside the tech giants’ platforms</b>. How can we organize, how can we click “Attend,” without <b>providing private data</b> to Facebook or <b>locking ourselves up</b> inside MeetUp?')" />
                        <p v-html="$t('Mobilizon is a free/libre software that will allow communities to create <b>their own spaces</b> to publish events in order to better emancipate themselves from tech giants.')" />
                    </div>
                    <div class="column has-text-right-desktop has-text-centered-mobile">
                        <img src="img/about/action-mobilizon.png" width="300" />
                    </div>
                </div>
            </section>
            <section>
                <div class="columns">
                    <div class="column has-text-right-desktop">
                        <h3 class="title">{{ $t("Let's create a new common") }}</h3>
                        <p v-html="$t('We want to develop a <b>digital common</b>, that everyone can make their own, which respects <b>privacy and activism by design</b>.')" />
                        <p>
                            <span v-html="$t('Installing Mobilizon will allow communities to free themselves from the services of tech giants by creating <b>their own event platform</b>.')" />
                            <i18n tag="span" path="This installation (called “instance“) can easily {interconnect}, thanks to {protocol}.">
                                <b slot="interconnect">{{ $t('interconnect with others like it') }}</b>
                                <a slot="protocol" href="https://en.wikipedia.org/wiki/ActivityPub">{{ $t('a decentralised federation protocol') }}</a>
                            </i18n>
                        </p>
                    </div>
                    <div class="column has-text-left-desktop has-text-centered-mobile">
                        <img src="img/about/common-mobilizon.png" width="300" />
                    </div>
                </div>
            </section>
        </div>
        <div class="hero quote is-secondary">
            <div class="hero-body">
                <div class="container">
                    <h3 class="title">{{ $t('To change the world, change the software') }}</h3>
                    <blockquote>
                        {{ $t('We won’t change the world from Facebook. The tool we dream of, surveillance capitalism corporations won’t develop it, as they couldn’t profit from it. This is an opportunity to build something better, by taking another approach.') }}</blockquote>
                    <footer class="blockquote-footer">
                        <a href="https://framablog.org/2019/05/14/mobilizon-lets-finance-a-software-to-free-our-events-from-facebook/">
                            {{ $t('Read Framasoft’s statement of intent on the Framablog') }}
                        </a>
                    </footer>
                </div>
            </div>
        </div>
        <div class="container">
            <section>
                <div class="columns">
                    <div class="column">
                        <h3 class="title">{{ $t('Software to the people') }}</h3>
                        <i18n tag="p" path="{license} guarantees {respect} of the people who will use it. Since {source}, anyone can audit it, which guarantees its transparency.">
                            <a slot="license" href="https://choosealicense.com/licenses/agpl-3.0/">{{ $t('Mobilizon’s licence') }}</a>
                            <b slot="respect">{{ $t('respect of the fundamental freedoms') }}</b>
                            <a slot="source" href="https://framagit.org/framasoft/mobilizon">{{ $t('its source code is public') }}</a>
                        </i18n>
                        <p>
                            If the direction given by the development team does not suit you,
                             you have the legal right to create your own version of the software,
                             with your own governance choices.
                        </p>
                        <p>
                            Mobilizon is not developed by a secretive start-up, but by a group
                            of friends who strive to <a href="https://framasoft.org">change the world, one byte at a time</a>.
                            So while we do work slower, we remain attentive and in touch with our users.
                        </p>
                    </div>
                    <div class="column has-text-right-desktop has-text-centered-mobile">
                        <img src="img/about/software-to-the-people-mobilizon.png" width="300" />
                    </div>
                </div>
            </section>
            <section>
                <div class="columns">
                    <div class="column has-text-right-desktop">
                        <h3 class="title">Concieved with care for humans</h3>
                        <p>We asked professional designers to help us develop our vision for Mobilizon.
                            We took time to study the <b>digital habits of activists</b> in order to
                            understand the features they need to gather, organize, and mobilize.
                        </p>
                        <p>
                            So that, right from its conception, Mobilizon would <b>fit the needs and uses of
                            the people</b> who are going to use it.
                        </p>
                    </div>
                    <div class="column has-text-left-desktop has-text-centered-mobile">
                        <img src="img/about/concieved-mobilizon.png" width="300" />
                    </div>
                </div>
            </section>
        </div>
        <!-- We hide the "Find an instance button until https://joinmobilizon.org gets a instance picker -->
        <div class="hero register is-primary is-medium" v-if="config && config.registrationsOpen">
            <div class="hero-body">
                <div class="container has-text-centered">
                    <div class="columns">
                        <div class="column">
                            <h2 class="title">Register on this instance</h2>
                            <b-button type="is-secondary" size="is-large" tag="router-link" :to="{ name: RouteName.REGISTER }">{{ $t('Register') }}</b-button>
                        </div>
                        <!-- <div class="column">
                            <h2 class="title">Find an instance</h2>
                            <b-button type="is-secondary" size="is-large" tag="a" href="https://joinmobilizon.org">{{ $t('Register') }}</b-button>
                        </div> -->
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script lang="ts">
import {
    Component,
    Vue,
} from 'vue-property-decorator';
import { CONFIG } from '@/graphql/config';
import { IConfig } from '@/types/config.model';
import { RouteName } from '@/router';

@Component({
  apollo: {
    config: {
      query: CONFIG,
    },
  },
})
export default class About extends Vue {
  config!: IConfig;

  RouteName = RouteName;
}
</script>

<style lang="scss" scoped>
    @import "@/variables.scss";

    .hero.register {
        background: lighten($primary, 20%);
    }

    section {
        padding: 3rem 0;

        &:not(:last-child) {
            border-bottom: 0.1rem dotted #777;
        }

        p {
            margin-top: 1.5rem;
        }

        &:nth-child(odd) .columns {
            flex-direction: row-reverse;
        }
    }

    .hero.quote {
        background: lighten($secondary, 20%);
        h3 {
            background: initial;
        }

        blockquote {
            border-left: .2em solid #333;
            display: block;
            padding-left: 1em;

            &:before {
                content: "« ";
            }

            &:after {
                content: " »";
            }
        }

        .blockquote-footer a {
            color: #6c757d;

            &:before {
                content: "\2014\00A0";
            }
        }
    }
</style>