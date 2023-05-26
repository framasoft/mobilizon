<template>
  <div
    class="flex flex-1 items-center w-full bg-white dark:bg-transparent"
    dir="auto"
  >
    <a :href="resource.resourceUrl" target="_blank">
      <div
        class="min-w-fit relative flex items-center justify-center text-mbz-purple dark:text-mbz-purple-300"
      >
        <div
          v-if="
            resource.type &&
            Object.keys(mapServiceTypeToIcon).includes(resource.type)
          "
        >
          <o-icon
            :icon="mapServiceTypeToIcon[resource.type]"
            size="large"
            customSize="48"
          />
        </div>
        <img
          v-else-if="resource.metadata && resource.metadata.imageRemoteUrl"
          :src="resource.metadata.imageRemoteUrl"
          alt=""
          height="48"
          width="48"
        />
        <div class="preview-type" v-else>
          <Link :size="48" />
        </div>
      </div>
      <div class="body flex-1 px-1 pb-1">
        <div class="flex items-center gap-1 max-w-[65vw]">
          <img
            class="favicon"
            alt=""
            v-if="resource.metadata && resource.metadata.faviconUrl"
            :src="resource.metadata.faviconUrl"
          />
          <h3 class="dark:text-white">{{ resource.title }}</h3>
        </div>
        <div class="metadata-wrapper">
          <span class="host" v-if="!inline || preview">{{ urlHostname }}</span>
          <span
            class="hidden md:inline"
            :class="{ inline }"
            v-if="resource.updatedAt || resource.publishedAt"
            >{{
              formatDateTimeString(
                resource.updatedAt ?? resource.publishedAt ?? ""
              )
            }}</span
          >
        </div>
      </div>
    </a>
    <resource-dropdown
      class="flex-0 block mx-auto my-2 cursor-pointer mr-2"
      v-if="!inline && !preview"
      @delete="emit('delete', resource.id as string)"
      @move="emit('move', resource)"
      @rename="emit('rename', resource)"
    />
  </div>
</template>
<script lang="ts" setup>
import { IResource, mapServiceTypeToIcon } from "@/types/resource";
import ResourceDropdown from "@/components/Resource/ResourceDropdown.vue";
import { computed } from "vue";
import { formatDateTimeString } from "@/filters/datetime";
import Link from "vue-material-design-icons/Link.vue";

const props = withDefaults(
  defineProps<{
    resource: IResource;
    inline?: boolean;
    preview?: boolean;
  }>(),
  { inline: false, preview: false }
);

const emit = defineEmits<{
  (e: "move", resource: IResource): void;
  (e: "rename", resource: IResource): void;
  (e: "delete", resourceID: string): void;
}>();

// const list = ref([]);

const urlHostname = computed((): string | undefined => {
  if (props.resource?.resourceUrl) {
    return new URL(props.resource.resourceUrl).hostname.replace(/^(www\.)/, "");
  }
  return undefined;
});
</script>
<style lang="scss" scoped>
@use "@/styles/_mixins" as *;

a {
  display: flex;
  font-size: 14px;
  // color: #444b5d;
  text-decoration: none;
  overflow: hidden;
  flex: 1;

  .body {
    img.favicon {
      display: inline-block;
      width: 16px;
      height: 16px;
      // @include margin-right(6px);
      vertical-align: middle;
    }

    h3 {
      white-space: nowrap;
      display: inline-block;
      font-weight: 500;
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
