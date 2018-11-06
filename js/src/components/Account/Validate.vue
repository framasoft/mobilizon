<template>
  <v-container>
    <h1 v-if="loading"><translate>Your account is being validated</translate></h1>
    <div v-else>
      <div v-if="failed">
        <v-alert :value="true" variant="danger"><translate>Error while validating account</translate></v-alert>
      </div>
      <h1 v-else><translate>Your account has been validated</translate></h1>
    </div>
  </v-container>
</template>

<script>
import { VALIDATE_USER } from '@/graphql/user';

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
      this.$apollo.mutate({
        mutation: VALIDATE_USER,
        variables: {
          token: this.token,
        },
      }).then((data) => {
        this.loading = false;
        console.log(data);
        this.saveUserData(data.data);
        this.$router.push({name: 'Home'});
      }).catch((error) => {
        this.loading = false;
        console.log(error);
        this.failed = true;
      });
    },
    saveUserData({validateUser: login}) {
      localStorage.setItem(AUTH_USER_ID, login.user.id);
      localStorage.setItem(AUTH_USER_ACTOR, JSON.stringify(login.actor));
      localStorage.setItem(AUTH_TOKEN, login.token);
    }
  },
};
</script>
