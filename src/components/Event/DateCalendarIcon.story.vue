<template>
  <Story>
    <Variant title="new">
      <DateCalendarIcon :date="new Date().toString()" />
    </Variant>
    <Variant title="small">
      <DateCalendarIcon :date="new Date().toString()" :small="true" />
    </Variant>
  </Story>
</template>

<script lang="ts" setup>
import DateCalendarIcon from "./DateCalendarIcon.vue";
</script>
