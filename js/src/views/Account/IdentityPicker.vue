<template>
  <div class="p-6">
    <header class="">
      <h2 class="">{{ $t("Pick an identity") }}</h2>
    </header>
    <section class="">
      <div class="list is-hoverable list-none">
        <a
          class="my-2 block dark:bg-violet-3 rounded-xl p-2"
          v-for="identity in identities"
          :key="identity.id"
          :class="{
            active: currentIdentity && identity.id === currentIdentity.id,
          }"
          @click="currentIdentity = identity"
        >
          <div class="flex gap-2">
            <img
              class="rounded"
              v-if="identity.avatar"
              :src="identity.avatar.url"
              alt=""
              width="48"
              height="48"
            />
            <AccountCircle v-else :size="48" />
            <div class="">
              <p>@{{ identity.preferredUsername }}</p>
              <small>{{ identity.name }}</small>
            </div>
          </div>
        </a>
      </div>
    </section>
    <slot name="footer" />
  </div>
</template>
<script lang="ts" setup>
import { IPerson } from "@/types/actor";
import { useCurrentUserIdentities } from "@/composition/apollo/actor";
import { computed } from "vue";
import AccountCircle from "vue-material-design-icons/AccountCircle.vue";
import { useI18n } from "vue-i18n";
import { useHead } from "@vueuse/head";

const { identities } = useCurrentUserIdentities();

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => t("Identities")),
});

const props = defineProps<{
  modelValue: IPerson;
}>();

const emit = defineEmits(["update:modelValue"]);

const currentIdentity = computed<IPerson>({
  get(): IPerson {
    return props.modelValue;
  },
  set(identity: IPerson) {
    emit("update:modelValue", identity);
  },
});
</script>
