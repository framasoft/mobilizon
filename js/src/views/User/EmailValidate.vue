<template>
  <section class="section container">
    <h1 class="title" v-if="loading">
      {{ $t('Your email is being changed') }}
    </h1>
    <div v-else>
      <div v-if="failed">
        <b-message :title="$t('Error while changing email')" type="is-danger">
          {{ $t('Either the email has already been changed, either the validation token is incorrect.') }}
        </b-message>
      </div>
      <h1 class="title" v-else>
        {{ $t('Your email has been changed') }}
      </h1>
    </div>
  </section>
</template>

<script lang="ts">
import { VALIDATE_EMAIL } from '@/graphql/user';
import { Component, Prop, Vue } from 'vue-property-decorator';
import { RouteName } from '@/router';

@Component
export default class Validate extends Vue {
  @Prop({ type: String, required: true }) token!: string;

  loading = true;
  failed = false;

  async created() {
    await this.validateAction();
  }

  async validateAction() {
    try {
      await this.$apollo.mutate<{ validateEmail }>({
        mutation: VALIDATE_EMAIL,
        variables: {
          token: this.token,
        },
      });
      this.loading = false;
      return await this.$router.push({ name: RouteName.HOME });

    } catch (err) {
      console.error(err);
      this.failed = true;
    }
  }
}
</script>
