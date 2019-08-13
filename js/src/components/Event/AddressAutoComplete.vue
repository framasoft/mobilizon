<template>
    <b-field label="Find an address">
        <b-autocomplete
                :data="data"
                placeholder="e.g. 10 Rue Jangot"
                field="description"
                :loading="isFetching"
                @typing="getAsyncData"
                @select="option => selected = option">

            <template slot-scope="{option}">
                <b>{{ option.description }}</b>
                <p>
                    <small>{{ option.street }}</small>,&#32;
                    <small>{{ option.locality }}</small>
                </p>
            </template>
        </b-autocomplete>
    </b-field>
</template>
<script lang="ts">
import { Component, Prop, Vue, Watch } from 'vue-property-decorator';
import { IAddress } from '@/types/address.model';
import { ADDRESS } from '@/graphql/address';
@Component
export default class AddressAutoComplete extends Vue {

  @Prop({ required: false, default: () => [] }) initialData!: IAddress[];

  data: IAddress[] = this.initialData;
  selected: IAddress|null = null;
  isFetching: boolean = false;

  async getAsyncData(query) {
    if (!query.length) {
      this.data = [];
      return;
    }
    this.isFetching = true;
    const result = await this.$apollo.query({
      query: ADDRESS,
      variables: { query },
    });

    this.data = result.data.searchAddress as IAddress[];
  }

  @Watch('selected')
  updateSelected() {
    this.$emit('input', this.selected);
  }
}
</script>
