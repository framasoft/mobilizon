<template>
  <div>a</div>
</template>

<script lang="ts">
import { Component, Vue } from "vue-property-decorator";
import RouteName from "@/router/name";

@Component
export default class HomepageRedirectComponent extends Vue {
  created(): void {
    this.$router.replace({ name: RouteName.HOME });
  }
}
</script>
