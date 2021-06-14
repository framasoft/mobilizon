<template>
  <div class="resource-wrapper">
    <a :href="resource.resourceUrl" target="_blank">
      <div class="preview">
        <div
          v-if="
            resource.type &&
            Object.keys(mapServiceTypeToIcon).includes(resource.type)
          "
        >
          <b-icon :icon="mapServiceTypeToIcon[resource.type]" size="is-large" />
        </div>
        <div
          class="preview-image"
          v-else-if="resource.metadata && resource.metadata.imageRemoteUrl"
          :style="`background-image: url(${resource.metadata.imageRemoteUrl})`"
        />
        <div class="preview-type" v-else>
          <b-icon icon="link" size="is-large" />
        </div>
      </div>
      <div class="body">
        <div class="title-wrapper">
          <img
            class="favicon"
            v-if="resource.metadata && resource.metadata.faviconUrl"
            :src="resource.metadata.faviconUrl"
          />
          <h3>{{ resource.title }}</h3>
        </div>
        <div class="metadata-wrapper">
          <span class="host" v-if="!inline || preview">{{ urlHostname }}</span>
          <span
            class="published-at is-hidden-mobile"
            v-if="resource.updatedAt || resource.publishedAt"
            >{{
              (resource.updatedAt || resource.publishedAt)
                | formatDateTimeString
            }}</span
          >
        </div>
      </div>
    </a>
    <resource-dropdown
      class="actions"
      v-if="!inline || !preview"
      @delete="$emit('delete', resource.id)"
      @move="$emit('move', resource)"
      @rename="$emit('rename', resource)"
    />
  </div>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { IResource, mapServiceTypeToIcon } from "@/types/resource";
import ResourceDropdown from "@/components/Resource/ResourceDropdown.vue";

@Component({
  components: { ResourceDropdown },
})
export default class ResourceItem extends Vue {
  @Prop({ required: true, type: Object }) resource!: IResource;

  @Prop({ required: false, default: false }) inline!: boolean;
  @Prop({ required: false, default: false }) preview!: boolean;

  list = [];

  mapServiceTypeToIcon = mapServiceTypeToIcon;

  get urlHostname(): string | undefined {
    if (this.resource?.resourceUrl) {
      return new URL(this.resource.resourceUrl).hostname.replace(
        /^(www\.)/,
        ""
      );
    }
    return undefined;
  }
}
</script>
<style lang="scss" scoped>
.resource-wrapper {
  display: flex;
  flex: 1;
  align-items: center;
  width: 100%;

  .actions {
    flex: 0;
    display: block;
    margin: auto 1rem;
    cursor: pointer;
  }
}

a {
  display: flex;
  font-size: 14px;
  color: #444b5d;
  text-decoration: none;
  overflow: hidden;
  flex: 1;

  .preview {
    flex: 0 0 50px;
    position: relative;
    display: flex;
    align-items: center;
    justify-content: center;

    .preview-image {
      border-radius: 4px 0 0 4px;
      display: block;
      margin: 0;
      width: 100%;
      height: 100%;
      object-fit: cover;
      background-size: cover;
      background-position: 50%;
    }
  }

  .body {
    padding: 8px;
    flex: 1 1 auto;
    overflow: hidden;

    .title-wrapper {
      display: flex;
      max-width: calc(100vw - 122px);
    }

    img.favicon {
      display: inline-block;
      width: 16px;
      height: 16px;
      margin-right: 6px;
      vertical-align: middle;
    }

    h3 {
      white-space: nowrap;
      display: inline-block;
      font-weight: 500;
      color: $primary;
      overflow: hidden;
      text-overflow: ellipsis;
      text-decoration: none;
      vertical-align: middle;
    }

    .metadata-wrapper {
      max-width: calc(100vw - 122px);
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
      span {
        &:last-child::before {
          content: "⋅";
          padding: 0 5px;
        }
        &:first-child::before {
          content: "";
          padding: initial;
        }

        &.host,
        &.published-at {
          font-size: 13px;
          overflow: hidden;
          text-overflow: ellipsis;
          white-space: nowrap;
        }
      }
    }
  }
}
</style>
