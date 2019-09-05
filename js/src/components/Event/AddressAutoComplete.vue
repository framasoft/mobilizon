<template>
    <div>
        <b-field label="Find an address">
            <b-autocomplete
                    :data="data"
                    v-model="queryText"
                    placeholder="e.g. 10 Rue Jangot"
                    field="description"
                    :loading="isFetching"
                    @typing="getAsyncData"
                    @select="option => selected = option">

                <template slot-scope="{option}">
                    <b>{{ option.description }}</b><br />
                    <i v-if="option.url != null">Local</i>
                    <p>
                        <small>{{ option.street }},&#32; {{ option.postalCode }} {{ option.locality }}</small>
                    </p>
                </template>
                <template slot="empty">
                    <span v-if="queryText.length < 5">Please type at least 5 caracters</span>
                    <span v-else-if="isFetching">Searching…</span>
                    <div v-else class="is-enabled">
                        <span>No results for « {{ queryText }} »</span>
                        <p class="control" @click="addressModalActive = true">
                            <button type="button" class="button is-primary">Add</button>
                        </p>
                    </div>
                </template>
            </b-autocomplete>
        </b-field>
        <b-modal :active.sync="addressModalActive" :width="640" has-modal-card scroll="keep">
            <div class="modal-card" style="width: auto">
                <header class="modal-card-head">
                    <p class="modal-card-title">Login</p>
                </header>
                <section class="modal-card-body">
                    <form>
                        <b-field :label="$gettext('Name')">
                            <b-input aria-required="true" required v-model="selected.description" />
                        </b-field>

                        <b-field :label="$gettext('Street')">
                            <b-input v-model="selected.street" />
                        </b-field>

                        <b-field :label="$gettext('Postal Code')">
                            <b-input v-model="selected.postalCode" />
                        </b-field>

                        <b-field :label="$gettext('Locality')">
                            <b-input v-model="selected.locality" />
                        </b-field>

                        <b-field :label="$gettext('Region')">
                            <b-input v-model="selected.region" />
                        </b-field>

                        <b-field :label="$gettext('Country')">
                            <b-input v-model="selected.country" />
                        </b-field>
                    </form>
                </section>
                <footer class="modal-card-foot">
                    <button class="button" type="button" @click="resetPopup()">Clear</button>
                </footer>
            </div>
        </b-modal>
    </div>
</template>
<script lang="ts">
import { Component, Prop, Vue, Watch } from 'vue-property-decorator';
import { Address, IAddress } from '@/types/address.model';
import { ADDRESS } from '@/graphql/address';
import { Modal } from 'buefy/dist/components/dialog';
@Component({
  components: {
    Modal,
  },
})
export default class AddressAutoComplete extends Vue {

  @Prop({ required: false, default: () => [] }) initialData!: IAddress[];
  @Prop({ required: false }) value!: IAddress;

  data: IAddress[] = this.initialData;
  selected: IAddress|null = new Address();
  isFetching: boolean = false;
  queryText: string = this.value && this.value.description || '';
  addressModalActive: boolean = false;

  async getAsyncData(query) {
    if (query.length < 5) {
      this.data = [];
      return;
    }
    this.isFetching = true;
    const result = await this.$apollo.query({
      query: ADDRESS,
      fetchPolicy: 'no-cache',
      variables: { query },
    });

    this.data = result.data.searchAddress as IAddress[];
    this.isFetching = false;
  }

  // Watch deep because of subproperties
  @Watch('selected', { deep: true })
  updateSelected() {
    this.$emit('input', this.selected);
  }

  resetPopup() {
    this.selected = new Address();
  }
}
</script>
<style lang="scss">
    .autocomplete .dropdown-item.is-disabled .is-enabled {
        opacity: 1 !important;
        cursor: auto;
    }
</style>
