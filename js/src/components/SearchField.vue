<template>
  <b-field label-for="navSearchField" class="-mt-2">
    <b-input
      :placeholder="defaultPlaceHolder"
      type="search"
      id="navSearchField"
      icon="magnify"
      icon-clickable
      rounded
      custom-class="searchField"
      dir="auto"
      v-model="search"
      @keyup.native.enter="enter"
    >
    </b-input>
    <template #label>
      <span class="sr-only">{{ defaultPlaceHolder }}</span>
    </template>
  </b-field>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import RouteName from "../router/name";

@Component
export default class SearchField extends Vue {
  @Prop({ type: String, required: false }) placeholder!: string;

  search = "";

  async enter(): Promise<void> {
    this.$emit("navbar-search");
    await this.$router.push({
      name: RouteName.SEARCH,
      query: { term: this.search },
    });
  }

  get defaultPlaceHolder(): string {
    // We can't use "this" inside @Prop's default value.
    return this.placeholder || (this.$t("Search") as string);
  }
}
</script>

<style lang="scss">
label span.visually-hidden {
  display: none;
}

input.searchField {
  box-shadow: none;
  border-color: #b5b5b5;
  border-radius: 9999px !important;

  &::placeholder {
    color: gray;
  }
}
</style>
