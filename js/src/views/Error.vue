<template>
  <section class="container">
    <span v-if="code === ErrorCode.REGISTRATION_CLOSED">
      {{ $t("Registration is currently closed.") }}
    </span>

    <span v-else>
      {{ $t("Unknown error.") }}
    </span>
  </section>
</template>

<script lang="ts">
import { ErrorCode } from "@/types/enums";
import { Component, Vue } from "vue-property-decorator";

@Component
export default class ErrorPage extends Vue {
  code: ErrorCode | null = null;

  ErrorCode = ErrorCode;

  mounted(): void {
    this.code = this.$route.query.code as ErrorCode;
  }
}
</script>
