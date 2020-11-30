<template>
  <label for="navSearchField">
    <span class="visually-hidden">{{ defaultPlaceHolder }}</span>
    <b-input
      custom-class="searchField"
      id="navSearchField"
      icon="magnify"
      type="search"
      rounded
      :placeholder="defaultPlaceHolder"
      v-model="search"
      @keyup.native.enter="enter"
    />
  </label>
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

  &::placeholder {
    color: gray;
  }
}
</style>
