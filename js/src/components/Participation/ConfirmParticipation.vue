<template>
    <section class="container">
        <h1 class="title" v-if="loading">
            {{ $t('Your participation is being validated') }}
        </h1>
        <div v-else>
            <div v-if="failed">
                <b-message :title="$t('Error while validating participation')" type="is-danger">
                    {{ $t('Either the participation has already been validated, either the validation token is incorrect.') }}
                </b-message>
            </div>
            <h1 class="title" v-else>
                {{ $t('Your participation has been validated') }}
            </h1>
        </div>
    </section>
</template>

<script lang="ts">
import { Component, Prop, Vue } from 'vue-property-decorator';
import { RouteName } from '@/router';
import { IParticipant } from '@/types/event.model';
import { CONFIRM_PARTICIPATION } from '@/graphql/event';
import { confirmLocalAnonymousParticipation } from '@/services/AnonymousParticipationStorage';

@Component
export default class ConfirmParticipation extends Vue {
  @Prop({ type: String, required: true }) token!: string;

  loading = true;
  failed = false;

  async created() {
    await this.validateAction();
  }

  async validateAction() {
    try {
      const { data } = await this.$apollo.mutate<{ confirmParticipation: IParticipant }>({
        mutation: CONFIRM_PARTICIPATION,
        variables: {
          token: this.token,
        },
      });

      if (data) {
        const { confirmParticipation: participation } = data;
        await confirmLocalAnonymousParticipation(participation.event.uuid);
        await this.$router.replace({ name: RouteName.EVENT, params: { uuid: data.confirmParticipation.event.uuid } } );
      }
    } catch (err) {
      console.error(err);
      this.failed = true;
    } finally {
      this.loading = false;
    }
  }
}
</script>
