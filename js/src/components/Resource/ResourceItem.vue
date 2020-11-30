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
        <img
          class="favicon"
          v-if="resource.metadata && resource.metadata.faviconUrl"
          :src="resource.metadata.faviconUrl"
        />
        <h3>{{ resource.title }}</h3>
        <span class="host" v-if="inline">{{
          resource.updatedAt | formatDateTimeString
        }}</span>
        <span class="host" v-else>{{ urlHostname }}</span>
      </div>
    </a>
    <resource-dropdown
      class="actions"
      v-if="!inline"
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

  list = [];

  mapServiceTypeToIcon = mapServiceTypeToIcon;

  get urlHostname(): string {
    return new URL(this.resource.resourceUrl).hostname.replace(/^(www\.)/, "");
  }
}
</script>
<style lang="scss" scoped>
.resource-wrapper {
  display: flex;
  flex: 1;
  align-items: center;

  .actions {
    flex: 0;
    display: block;
    margin: auto 1rem auto 2rem;
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
    padding: 10px 8px 8px;
    flex: 1 1 auto;
    overflow: hidden;

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
      margin-bottom: 5px;
      color: $primary;
      overflow: hidden;
      text-overflow: ellipsis;
      text-decoration: none;
      vertical-align: middle;
    }

    .host {
      display: block;
      margin-top: 5px;
      font-size: 13px;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
  }
}
</style>
