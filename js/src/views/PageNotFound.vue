<template>
  <section class="section container has-text-centered not-found">
    <div class="columns is-vertical is-centered">
      <div class="column is-half">
        <picture>
          <source
            srcset="/img/pics/error-480w.webp 1x, /img/pics/error-1024w.webp 2x"
            type="image/webp"
          />
          <source
            srcset="/img/pics/error-480w.jpg 1x, /img/pics/error-1024w.jpg 2x"
            type="image/jpeg"
          />

          <img
            :src="`/img/pics/error-480w.jpg`"
            alt=""
            width="2616"
            height="1698"
            loading="lazy"
          />
        </picture>
        <h1 class="title">
          {{ $t("The page you're looking for doesn't exist.") }}
        </h1>
        <p>
          {{
            $t(
              "Please make sure the address is correct and that the page hasn't been moved."
            )
          }}
        </p>
        <p>
          {{
            $t(
              "Please contact this instance's Mobilizon admin if you think this is a mistake."
            )
          }}
        </p>
        <!--  The following should just be replaced with the SearchField component but it fails for some reason  -->
        <form @submit="enter">
          <b-field class="search">
            <b-input
              expanded
              icon="magnify"
              type="search"
              :placeholder="searchPlaceHolder"
              v-model="searchText"
            />
            <p class="control">
              <button type="submit" class="button is-primary">
                {{ $t("Search") }}
              </button>
            </p>
          </b-field>
        </form>
      </div>
    </div>
  </section>
</template>
<script lang="ts">
import { Component, Vue } from "vue-property-decorator";
import BField from "buefy/src/components/field/Field.vue";
import RouteName from "../router/name";

@Component({
  components: {
    BField,
  },
})
export default class PageNotFound extends Vue {
  searchText = "";

  get searchPlaceHolder(): string {
    return this.$t("Search events, groups, etc.") as string;
  }

  async enter(): Promise<void> {
    await this.$router.push({
      name: RouteName.SEARCH,
      query: { term: this.searchText },
    });
  }
}
</script>
<style lang="scss">
.container.not-found {
  margin: auto;
  background: $white;

  img {
    margin-top: 3rem;
  }

  p {
    margin-bottom: 1em;
  }
}
</style>
