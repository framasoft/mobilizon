<template>
    <b-input icon="magnify" type="search" rounded :placeholder="defaultPlaceHolder" v-model="searchText" @keyup.native.enter="enter" />
</template>
<script lang="ts">
import { Component, Prop, Vue } from 'vue-property-decorator';
import { RouteName } from '@/router';

@Component
export default class SearchField extends Vue {
  @Prop({ type: String, required: false }) placeholder!: string;
  searchText: string = '';

  enter() {
    this.$router.push({ name: RouteName.SEARCH, params: { searchTerm: this.searchText } });
  }

  get defaultPlaceHolder(): string {
      // We can't use "this" inside @Prop's default value.
    return this.placeholder || this.$t('Search') as string;
  }
}
</script>
