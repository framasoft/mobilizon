<template>
  <div>a</div>
</template>

<script lang="ts" setup>
import RouteName from "@/router/name";
import { useRouter } from "vue-router";

const router = useRouter();

router.replace({ name: RouteName.HOME });
</script>
