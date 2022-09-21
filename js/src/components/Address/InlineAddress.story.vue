<template>
  <Story>
    <Variant title="with locality">
      <InlineAddress :physicalAddress="address" />
    </Variant>

    <Variant title="without locality">
      <InlineAddress :physicalAddress="{ ...address, locality: null }" />
    </Variant>
  </Story>
</template>
<script lang="ts" setup>
import { IAddress } from "@/types/address.model";
import { reactive } from "vue";
import InlineAddress from "./InlineAddress.vue";

const address = reactive<IAddress>({
  description: "Locaux Motiv",
  street: "10 Rue Jangot",
  locality: "Lyon",
  postalCode: "69007",
  region: "Auvergne Rhône-Alpes",
  country: "France",
  type: "",
  timezone: "Europe/Dublin",
});
</script>
