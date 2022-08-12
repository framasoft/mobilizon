<template>
  <Story>
    <Variant :title="'Open'">
      <UnloggedIntroduction :config="config" />
    </Variant>
    <Variant :title="'Closed'">
      <UnloggedIntroduction :config="configClosed" />
    </Variant>
  </Story>
</template>
<script lang="ts" setup>
import { reactive } from "vue";
import UnloggedIntroduction from "./UnloggedIntroduction.vue";

const config = reactive({
  name: "My instance name",
  description: "An instance that doesn't exist",
  slogan: "Test! Test! Test!",
  registrationsOpen: true,
});

const configClosed = reactive({ ...config, registrationsOpen: false });
</script>
