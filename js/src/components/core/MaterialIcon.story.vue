<template>
  <Story :layout="{ type: 'grid', width: 60 }">
    <Variant title="Google">
      <MaterialIcon :icon="['', 'google']" />
    </Variant>
    <Variant title="Calendar">
      <MaterialIcon :icon="['', 'calendar']" />
    </Variant>
    <Variant title="Account Multiple Plus">
      <MaterialIcon :icon="['', 'account-multiple-plus']" />
    </Variant>
  </Story>
</template>
<script lang="ts" setup>
import MaterialIcon from "./MaterialIcon.vue";
</script>
