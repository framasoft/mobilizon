<template>
  <div>
    <header class="">
      <h2 class="">{{ t("Pick an identity") }}</h2>
    </header>
    <section class="">
      <transition-group
        tag="ul"
        class="grid grid-cols-1 gap-y-3 m-5 max-w-md"
        enter-active-class="duration-300 ease-out"
        enter-from-class="transform opacity-0"
        enter-to-class="opacity-100"
        leave-active-class="duration-200 ease-in"
        leave-from-class="opacity-100"
        leave-to-class="transform opacity-0"
      >
        <li
          class="relative focus-within:shadow-lg"
          v-for="identity in identities"
          :key="identity?.id"
        >
          <input
            class="sr-only peer"
            type="radio"
            :value="identity"
            name="availableActors"
            v-model="currentIdentity"
            :id="`availableActor-${identity?.id}`"
          />
          <label
            class="flex items-center gap-2 p-3 bg-white hover:bg-gray-50 dark:bg-violet-3 dark:hover:bg-violet-3/60 border border-gray-300 rounded-lg cursor-pointer peer-checked:ring-primary peer-checked:ring-2 peer-checked:border-transparent"
            :for="`availableActor-${identity?.id}`"
          >
            <figure class="h-12 w-12" v-if="identity?.avatar">
              <img
                class="rounded-full h-full w-full object-cover"
                :src="identity.avatar.url"
                alt=""
                width="48"
                height="48"
              />
            </figure>
            <AccountCircle v-else :size="48" />
            <div class="flex-1 w-px">
              <h3 class="line-clamp-2">{{ identity?.name }}</h3>
              <small class="flex truncate">{{
                `@${identity?.preferredUsername}`
              }}</small>
            </div>
          </label>
        </li>
      </transition-group>
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

const { identities } = useCurrentUserIdentities();

const { t } = useI18n({ useScope: "global" });

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
