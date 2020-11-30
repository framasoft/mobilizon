<template>
  <div class="modal-card">
    <header class="modal-card-head">
      <p class="modal-card-title">{{ $t("Pick an identity") }}</p>
    </header>
    <section class="modal-card-body">
      <div class="list is-hoverable">
        <a
          class="list-item"
          v-for="identity in identities"
          :key="identity.id"
          :class="{ 'is-active': identity.id === currentIdentity.id }"
          @click="changeCurrentIdentity(identity)"
        >
          <div class="media">
            <img
              class="media-left image is-48x48"
              v-if="identity.avatar"
              :src="identity.avatar.url"
              alt=""
            />
            <b-icon
              class="media-left"
              v-else
              size="is-large"
              icon="account-circle"
            />
            <div class="media-content">
              <h3>@{{ identity.preferredUsername }}</h3>
              <small>{{ identity.name }}</small>
            </div>
          </div>
        </a>
      </div>
    </section>
    <slot name="footer" />
  </div>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { IActor } from "@/types/actor";
import { IDENTITIES } from "@/graphql/actor";

@Component({
  apollo: {
    identities: {
      query: IDENTITIES,
    },
  },
})
export default class IdentityPicker extends Vue {
  @Prop() value!: IActor;

  identities: IActor[] = [];

  currentIdentity: IActor = this.value;

  changeCurrentIdentity(identity: IActor): void {
    this.currentIdentity = identity;
    this.$emit("input", identity);
  }
}
</script>
