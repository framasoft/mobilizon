<template>
  <div v-if="code === ErrorCode.REGISTRATION_CLOSED">
    <translate>Registration is currently closed.</translate>
  </div>

  <div v-else>
    <translate>Unknown error.</translate>
  </div>
</template>

<script lang="ts">
  import { Component, Vue } from 'vue-property-decorator';
  import { ErrorCode } from '@/types/error-code.model';

  @Component
  export default class ErrorPage extends Vue {
    code: ErrorCode | null = null;

    ErrorCode = ErrorCode;

    mounted() {
      this.code = this.$route.query[ 'code' ] as ErrorCode;
    }
  }
</script>
