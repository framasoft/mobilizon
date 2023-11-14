<template>
  <section class="container mx-auto">
    <h1 class="title" v-if="loading">
      {{ t("Your email is being changed") }}
    </h1>
    <div v-else>
      <div v-if="failed">
        <o-notification
          :title="t('Error while changing email')"
          variant="danger"
        >
          {{
            t(
              "Either the email has already been changed, either the validation token is incorrect."
            )
          }}
        </o-notification>
      </div>
      <h1 class="title" v-else>{{ t("Your email has been changed") }}</h1>
    </div>
  </section>
</template>

<script lang="ts" setup>
import { useMutation } from "@vue/apollo-composable";
import { ref, onBeforeMount } from "vue";
import { useI18n } from "vue-i18n";
import { useRouter } from "vue-router";
import { VALIDATE_EMAIL } from "../../graphql/user";
import RouteName from "../../router/name";

// metaInfo() {
//   return {
//     title: this.t("Validating email") as string,
//   };
// },
const props = defineProps<{
  token: string;
}>();

const loading = ref(true);
const failed = ref(false);
const router = useRouter();
const { t } = useI18n({ useScope: "global" });

onBeforeMount(() => validateEmail({ token: props.token }));

const { mutate: validateEmail, onDone, onError } = useMutation(VALIDATE_EMAIL);

onDone(async () => {
  loading.value = false;
  await router.push({ name: RouteName.HOME });
});
onError((err) => {
  loading.value = false;
  console.error(err);
  failed.value = true;
});
</script>
