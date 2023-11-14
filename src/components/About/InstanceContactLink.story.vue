<template>
  <Story>
    <Variant title="empty">
      <InstanceContactLink />
    </Variant>
    <Variant title="string">
      <InstanceContactLink contact="someone" />
    </Variant>
    <Variant title="email">
      <InstanceContactLink contact="someone@somewhere.tld" />
    </Variant>
    <Variant title="url">
      <InstanceContactLink contact="https://somewhere.com" />
    </Variant>
  </Story>
</template>

<script lang="ts" setup>
import InstanceContactLink from "./InstanceContactLink.vue";
</script>
