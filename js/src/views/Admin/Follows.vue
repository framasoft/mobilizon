<template>
    <section class="section container">
        <h1 class="title">{{ $t('Instances') }}</h1>
        <div class="tabs is-boxed">
            <ul>
                <router-link tag="li" active-class="is-active" :to="{name: RouteName.RELAY_FOLLOWINGS}" exact>
                    <a>
                        <b-icon icon="inbox-arrow-down"></b-icon>
                        <span>{{ $t('Followings') }} <b-tag rounded> {{ relayFollowings.total }} </b-tag> </span>
                    </a>
                </router-link>
                <router-link tag="li" active-class="is-active" :to="{name: RouteName.RELAY_FOLLOWERS}" exact>
                    <a>
                        <b-icon icon="inbox-arrow-up"></b-icon>
                        <span>{{ $t('Followers') }} <b-tag rounded> {{ relayFollowers.total }} </b-tag> </span>
                    </a>
                </router-link>
            </ul>
        </div>
        <router-view></router-view>
    </section>
</template>

<script lang="ts">
import { Component, Vue } from 'vue-property-decorator';
import { RouteName } from '@/router';
import { RELAY_FOLLOWERS, RELAY_FOLLOWINGS } from '@/graphql/admin';
import { Paginate } from '@/types/paginate';
import { IFollower } from '@/types/actor/follower.model';

@Component({
  apollo: {
    relayFollowings: {
      query: RELAY_FOLLOWINGS,
      fetchPolicy: 'cache-and-network',
    },
    relayFollowers: {
      query: RELAY_FOLLOWERS,
      fetchPolicy: 'cache-and-network',
    },
  },
})
export default class Follows extends Vue {
  RouteName = RouteName;
  activeTab: number = 0;

  relayFollowings: Paginate<IFollower> = { elements: [], total: 0 };
  relayFollowers: Paginate<IFollower> = { elements: [], total: 0 };
}
</script>
<style lang="scss">
    .tab-item {
        form {
            margin-bottom: 1.5rem;
        }
    }
</style>