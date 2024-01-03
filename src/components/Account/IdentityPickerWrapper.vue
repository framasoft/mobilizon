<template>
  <div>
    <div
      v-if="inline && currentIdentity"
      class="inline box cursor-pointer"
      @click="activateModal"
    >
      <div class="flex gap-1">
        <div class="">
          <figure class="" v-if="currentIdentity.avatar">
            <img
              class="rounded-full"
              :src="currentIdentity.avatar.url"
              alt=""
              width="48"
              height="48"
            />
          </figure>
          <AccountCircle v-else :size="48" />
        </div>
        <div class="" v-if="currentIdentity.name">
          <p class="">{{ currentIdentity.name }}</p>
          <p class="">
            {{ `@${currentIdentity.preferredUsername}` }}
            <span v-if="masked">{{ t("(Masked)") }}</span>
          </p>
        </div>
        <div class="" v-else>
          {{ `@${currentIdentity.preferredUsername}` }}
        </div>
        <o-button
          variant="text"
          v-if="identities && identities.length > 1"
          @click="activateModal"
        >
          {{ t("Change") }}
        </o-button>
      </div>
    </div>
    <span
      v-else-if="currentIdentity"
      class="cursor-pointer"
      @click="activateModal"
    >
      <figure class="h-12 w-12" v-if="currentIdentity.avatar">
        <img
          class="rounded-full object-cover h-full"
          :src="currentIdentity.avatar.url"
          alt=""
          width="48"
          height="48"
        />
      </figure>
      <AccountCircle v-else :size="48" />
    </span>
    <o-modal
      v-model:active="isComponentModalActive"
      :close-button-aria-label="t('Close')"
    >
      <identity-picker v-if="currentIdentity" v-model="currentIdentity" />
    </o-modal>
  </div>
</template>
<script lang="ts" setup>
import { useCurrentUserIdentities } from "@/composition/apollo/actor";
import { computed, ref } from "vue";
import { IPerson } from "../../types/actor";
import IdentityPicker from "./IdentityPicker.vue";
import AccountCircle from "vue-material-design-icons/AccountCircle.vue";
import { useI18n } from "vue-i18n";

const { identities } = useCurrentUserIdentities();

const props = withDefaults(
  defineProps<{
    modelValue: IPerson;
    inline?: boolean;
    masked?: boolean;
  }>(),
  {
    inline: true,
    masked: false,
  }
);

const emit = defineEmits(["update:modelValue"]);

const { t } = useI18n({ useScope: "global" });

const isComponentModalActive = ref(false);

const currentIdentity = computed({
  get(): IPerson | undefined {
    return props.modelValue;
  },
  set(identity: IPerson | undefined) {
    emit("update:modelValue", identity);
    isComponentModalActive.value = false;
  },
});

const hasOtherIdentities = computed((): boolean => {
  return identities.value !== undefined && identities.value.length > 1;
});

const activateModal = (): void => {
  if (hasOtherIdentities.value) {
    isComponentModalActive.value = true;
  }
};
</script>
