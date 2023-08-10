<template>
  <div class="container mx-auto w-96">
    <form
      @submit.prevent="() => validateCode({ userCode: code })"
      @paste="pasteCode"
      class="rounded-lg bg-white dark:bg-zinc-900 shadow-xl my-6 p-4"
      v-if="!application"
    >
      <h1 class="text-3xl text-center">
        {{ t("Device activation") }}
      </h1>
      <p class="mb-4 text-center">
        {{ t("Enter the code displayed on your device") }}
      </p>

      <div class="flex items-center justify-between mb-4 gap-2">
        <div
          v-for="i in Array(9).keys()"
          :key="i"
          :class="i === 4 ? 'w-6' : 'w-8'"
        >
          <span
            :id="`user-code-${i}`"
            v-if="i === 4"
            class="block text-3xl text-center"
            >-</span
          >
          <o-input
            autocapitalize="characters"
            @update:modelValue="
              (val: string) => (inputs[i] = val.toUpperCase())
            "
            :useHtml5Validation="true"
            :id="`user-code-${i}`"
            :ref="(el: Element) => (userCodeInputs[i] = el)"
            :modelValue="inputs[i]"
            v-else
            size="large"
            style="font-size: 22px; padding: 0.5rem 0.15rem 0.5rem 0.25rem"
            required
            maxlength="1"
            pattern="[A-Z]{1}"
            :autofocus="i === 0 ? true : undefined"
          />
        </div>
      </div>

      <div
        class="rounded-lg bg-mbz-danger shadow-xl my-6 p-4 flex items-center gap-2"
        v-if="error"
      >
        <AlertCircle :size="42" />
        <div>
          <p>{{ error }}</p>
        </div>
      </div>

      <div class="text-center">
        <o-button native-type="submit">{{ t("Continue") }}</o-button>
      </div>
    </form>
    <AuthorizeApplication
      v-if="application"
      :auth-application="application"
      :user-code="code"
      :scope="scope"
    />
  </div>
</template>

<script lang="ts" setup>
import { DEVICE_ACTIVATION } from "@/graphql/application";
import { useMutation } from "@vue/apollo-composable";
import { useHead } from "@vueuse/head";
import { computed, reactive, ref, watch } from "vue";
import { useI18n } from "vue-i18n";
import AuthorizeApplication from "@/components/OAuth/AuthorizeApplication.vue";
import { IApplication } from "@/types/application.model";
import { AbsintheGraphQLErrors } from "@/types/errors.model";
import AlertCircle from "vue-material-design-icons/AlertCircle.vue";

const { t } = useI18n({ useScope: "global" });

const {
  mutate: validateCode,
  onDone: onDeviceActivationDone,
  onError: onDeviceActivationError,
} = useMutation<{
  deviceActivation: { application: IApplication; id: string; scope: string };
}>(DEVICE_ACTIVATION);

const inputs = reactive<string[]>([]);

const application = ref<IApplication | null>(null);
const scope = ref<string | null>(null);

onDeviceActivationDone(({ data }) => {
  console.debug("onDeviceActivationDone", data);
  const foundApplication = data?.deviceActivation?.application;
  if (foundApplication) {
    application.value = foundApplication;
    scope.value = data?.deviceActivation?.scope;
  }
});

const code = computed(() => {
  return inputs.join("");
});

const userCodeInputs = reactive<Record<number, Element>>([]);

watch(inputs, (localInputs) => {
  localInputs.forEach((input, index) => {
    if (input && index < 8) {
      if (index === 3) {
        index = 4;
      }
      (userCodeInputs[index + 1] as HTMLInputElement).focus();
    }
  });
});

const error = ref<string | null>(null);

onDeviceActivationError(
  ({ graphQLErrors }: { graphQLErrors: AbsintheGraphQLErrors }) => {
    const err = graphQLErrors[0];
    if (
      err.status_code === 400 &&
      err.code === "device_application_code_expired"
    ) {
      error.value = t("The device code is incorrect or no longer valid.");
    }
    resetInputs();
    (userCodeInputs[0] as HTMLInputElement).focus();
    setTimeout(() => {
      error.value = null;
    }, 10000);
  }
);

const resetInputs = () => {
  inputs.splice(0);
};

const pasteCode = (e: ClipboardEvent) => {
  let pastedCode = e.clipboardData?.getData("text").trim();
  if (!pastedCode) return;
  if (pastedCode.match(/^[A-Z]{4}-[A-Z]{4}$/)) {
    pastedCode = pastedCode.slice(0, 4) + pastedCode.slice(5);
  }
  if (pastedCode.match(/^[A-Z]{8}$/)) {
    pastedCode.split("").forEach((val, index) => {
      const realIndex = index > 3 ? index + 1 : index;
      inputs[realIndex] = val;
    });
  }
};

useHead({
  title: computed(() => t("Device activation")),
});
</script>
