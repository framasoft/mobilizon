<template>
  <Story>
    <Variant title="Basic">
      <AddressInfo :address="address" />
    </Variant>

    <Variant title="Basic with timezone">
      <AddressInfo
        :address="address"
        :show-timezone="true"
        :user-timezone="'Europe/Berlin'"
      />
    </Variant>
  </Story>
</template>
<script lang="ts" setup>
import { IAddress } from "@/types/address.model";
import { reactive } from "vue";
import AddressInfo from "./AddressInfo.vue";

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
