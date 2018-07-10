<template>
  <v-container>
    <h1 v-if="loading">{{ $t('registration.validation.process') }}</h1>
    <div v-else>
      <div v-if="failed">
        <v-alert :value="true" variant="danger">Error while validating account</v-alert>
      </div>
      <h1 v-else>{{ $t('registration.validation.finished') }}</h1>
    </div>
  </v-container>
</template>

<script>
import fetchStory from '@/api/eventFetch';
import { LOGIN_USER } from '@/store/mutation-types';

export default {
  name: 'Validate',
  data() {
    return {
      loading: true,
      failed: false,
    };
  },
  props: {
    token: {
      type: String,
      required: true,
    },
  },
  created() {
    this.validateAction();
  },
  methods: {
    validateAction() {
      fetchStory(`/users/validate/${this.token}`, this.$store).then((data) => {
        this.loading = false;
        localStorage.setItem('token', data.token);
        localStorage.setItem('refresh_token', data.refresh_token);
        this.$store.commit(LOGIN_USER, data.account);
        this.$snotify.success(this.$t('registration.success.login', { username: data.account.username }));
        this.$router.push({ name: 'Home' });
      }).catch((err) => {
        Promise.resolve(err).then(() => {
          this.failed = true;
          this.loading = false;
        });
      });
    },
  },
};
</script>
