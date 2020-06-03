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
import { Component, Vue } from "vue-property-decorator";
import { ErrorCode } from "@/types/error-code.model";

@Component
export default class ErrorPage extends Vue {
  code: ErrorCode | null = null;

  ErrorCode = ErrorCode;

  mounted() {
    this.code = this.$route.query.code as ErrorCode;
  }
}
</script>
