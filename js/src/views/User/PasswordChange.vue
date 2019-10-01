<template>
    <section class="container">
        <nav class="breadcrumb" aria-label="breadcrumbs">
            <ul>
                <li><router-link :to="{ name: MyAccountRouteName.UPDATE_IDENTITY }">{{ $t('My account') }}</router-link></li>
                <li class="is-active"><router-link :to="{ name: UserRouteName.PASSWORD_CHANGE }" aria-current="page">{{ $t('Password change') }}</router-link></li>
            </ul>
        </nav>
        <h1 class="title">{{ $t('Password') }}</h1>
        <b-notification
                type="is-danger"
                has-icon
                aria-close-label="Close notification"
                role="alert"
                :key="error"
                v-for="error in errors"
        >
            {{ error }}
        </b-notification>
        <form @submit="resetAction" class="form">
            <b-field :label="$t('Old password')">
                <b-input
                        aria-required="true"
                        required
                        type="password"
                        password-reveal
                        minlength="6"
                        v-model="oldPassword"
                />
            </b-field>
            <b-field :label="$t('New password')">
                <b-input
                        aria-required="true"
                        required
                        type="password"
                        password-reveal
                        minlength="6"
                        v-model="newPassword"
                />
            </b-field>
            <button class="button is-primary">
                {{ $t('Change my password') }}
            </button>
        </form>
    </section>
</template>

<script lang="ts">
import { Component, Vue } from 'vue-property-decorator';
import { CHANGE_PASSWORD } from '@/graphql/user';
import { UserRouteName } from '@/router/user';
import { MyAccountRouteName } from '@/router/actor';

@Component
export default class PasswordChange extends Vue {
  oldPassword: string = '';
  newPassword: string = '';
  errors: string[] = [];

  MyAccountRouteName = MyAccountRouteName;
  UserRouteName = UserRouteName;

  async resetAction(e) {
    e.preventDefault();
    this.errors = [];

    try {
      await this.$apollo.mutate({
        mutation: CHANGE_PASSWORD,
        variables: {
          oldPassword: this.oldPassword,
          newPassword: this.newPassword,
        },
      });

      this.$notifier.success(this.$t('The password was successfully changed') as string);
    } catch (err) {
      this.handleError(err);
    }
  }

  private handleError(err: any) {
    console.error(err);

    if (err.graphQLErrors !== undefined) {
      err.graphQLErrors.forEach(({ message }) => {
        this.errors.push(message);
      });
    }
  }
}
</script>
<style lang="scss">
</style>
