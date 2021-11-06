<template>
  <router-link
    :to="{
      name: RouteName.GROUP,
      params: { preferredUsername: usernameWithDomain(group) },
    }"
    class="card"
  >
    <div class="card-image">
      <figure class="image is-16by9">
        <lazy-image-wrapper
          :picture="group.banner"
          style="height: 100%; position: absolute; top: 0; left: 0; width: 100%"
        />
      </figure>
    </div>
    <div class="card-content">
      <div class="media mb-3">
        <div class="media-left">
          <figure class="image is-48x48" v-if="group.avatar">
            <img class="is-rounded" :src="group.avatar.url" alt="" />
          </figure>
          <b-icon v-else size="is-large" icon="account-group" />
        </div>
        <div class="media-content">
          <h3 class="is-size-5 group-title">{{ displayName(group) }}</h3>
          <span class="is-6 has-text-grey-dark">
            {{ `@${usernameWithDomain(group)}` }}
          </span>
        </div>
      </div>
      <div class="content" v-html="group.summary" />
      <div class="card-custom-footer">
        <span class="has-text-grey-dark">
          {{
            $tc(
              "{count} members or followers",
              group.members.total + group.followers.total,
              {
                count: group.members.total + group.followers.total,
              }
            )
          }}
        </span>
      </div>
    </div>
  </router-link>
</template>

<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { displayName, IGroup, usernameWithDomain } from "@/types/actor";
import LazyImageWrapper from "@/components/Image/LazyImageWrapper.vue";
import RouteName from "../../router/name";

@Component({
  components: {
    LazyImageWrapper,
  },
})
export default class GroupCard extends Vue {
  @Prop({ required: true }) group!: IGroup;

  RouteName = RouteName;

  usernameWithDomain = usernameWithDomain;

  displayName = displayName;
}
</script>
<style lang="scss" scoped>
.card {
  .card-content {
    padding: 0.75rem;
    display: flex;
    flex-direction: column;
    height: 100%;

    .content {
      flex: 1;
    }

    ::v-deep .content {
      & > *:first-child {
        display: -webkit-box;
        -webkit-line-clamp: 3;
        -webkit-box-orient: vertical;
        overflow: hidden;
        margin-bottom: 0;

        * {
          font-weight: normal;
          text-transform: none;
          font-style: normal;
          text-decoration: none;
        }
      }
      & > *:not(:first-child) {
        display: none;
      }
    }

    .media-left {
      margin-right: inherit;
      margin-inline-end: 0.5rem;
    }

    .media-content {
      overflow: hidden;
      text-overflow: ellipsis;

      .group-title {
        line-height: 1.75rem;
        display: -webkit-box;
        -webkit-line-clamp: 3;
        -webkit-box-orient: vertical;
        overflow: hidden;
        font-weight: bold;
      }
    }
  }
}
</style>
