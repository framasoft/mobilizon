<template>
  <section class="container mx-auto">
    <div class="">
      <div class="">
        <h1 class="text-2xl" v-if="userAlreadyActivated">
          {{ $t("Congratulations, your account is now created!") }}
        </h1>
        <h1 class="text-2xl" v-else>
          {{
            $t("Register an account on {instanceName}!", {
              instanceName,
            })
          }}
        </h1>
        <p class="prose dark:prose-invert" v-if="userAlreadyActivated">
          {{ $t("Now, create your first profile:") }}
        </p>
        <form v-if="!validationSent" @submit.prevent="submit">
          <o-field :label="$t('Displayed nickname')">
            <o-input
              aria-required="true"
              required
              v-model="identity.name"
              @input="autoUpdateUsername"
            />
          </o-field>

          <o-field
            :label="$t('Username')"
            :type="errors.preferred_username ? 'is-danger' : null"
            :message="errors.preferred_username"
          >
            <o-field
              :message="
                $t(
                  'Only alphanumeric lowercased characters and underscores are supported.'
                )
              "
            >
              <o-input
                aria-required="true"
                required
                expanded
                v-model="identity.preferredUsername"
                :validation-message="
                  identity.preferredUsername
                    ? $t(
                        'Only alphanumeric lowercased characters and underscores are supported.'
                      )
                    : null
                "
              />
              <p class="control">
                <span class="button is-static">@{{ host }}</span>
              </p>
            </o-field>
          </o-field>
          <p class="description">
            {{
              $t(
                "This identifier is unique to your profile. It allows others to find you."
              )
            }}
          </p>

          <o-field :label="$t('Short bio')">
            <o-input
              type="textarea"
              maxlength="100"
              rows="2"
              v-model="identity.summary"
            />
          </o-field>

          <p class="prose dark:prose-invert">
            {{
              $t(
                "You will be able to add an avatar and set other options in your account settings."
              )
            }}
          </p>

          <p class="control has-text-centered">
            <o-button
              variant="primary"
              size="large"
              native-type="submit"
              :disabled="sendingValidation"
              >{{ $t("Create my profile") }}</o-button
            >
          </p>
        </form>

        <div v-if="validationSent && !userAlreadyActivated">
          <o-notification variant="success" :closable="false">
            <h2 class="title">
              {{
                $t("Your account is nearly ready, {username}", {
                  username: identity.name ?? identity.preferredUsername,
                })
              }}
            </h2>
            <i18n-t keypath="A validation email was sent to {email}" tag="p">
              <template #email>
                <code>{{ email }}</code>
              </template>
            </i18n-t>
            <p>
              {{
                $t(
                  "Before you can login, you need to click on the link inside it to validate your account."
                )
              }}
            </p>
          </o-notification>
        </div>
      </div>
    </div>
  </section>
</template>

<script lang="ts" setup>
import { Person } from "../../types/actor";
import { MOBILIZON_INSTANCE_HOST } from "../../api/_entrypoint";
import RouteName from "../../router/name";
import { changeIdentity } from "../../utils/identity";
import { useInstanceName } from "@/composition/apollo/config";
import { ref, computed, onBeforeMount } from "vue";
import { useRouter } from "vue-router";
import { registerAccount } from "@/composition/apollo/user";
import { convertToUsername } from "@/utils/username";
import { useI18n } from "vue-i18n";
import { useHead } from "@vueuse/head";

const props = withDefaults(
  defineProps<{
    email: string;
    userAlreadyActivated?: boolean;
  }>(),
  {
    userAlreadyActivated: false,
  }
);

const { instanceName } = useInstanceName();

const router = useRouter();

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => t("Register")),
});

const host: string = MOBILIZON_INSTANCE_HOST;

const errors = ref<Record<string, unknown>>({});

const validationSent = ref(false);

const sendingValidation = ref(false);

const identity = ref(new Person());

onBeforeMount(() => {
  // Make sure no one goes to this page if we don't want to
  if (!props.email) {
    router.replace({ name: RouteName.PAGE_NOT_FOUND });
  }
});

const autoUpdateUsername = () => {
  identity.value.preferredUsername = convertToUsername(identity.value.name);
};

const submit = async (): Promise<void> => {
  sendingValidation.value = true;
  errors.value = {};
  const { onDone, onError } = registerAccount(
    { email: props.email, ...identity.value },
    props.userAlreadyActivated
  );

  onDone(async ({ data }) => {
    validationSent.value = true;
    window.localStorage.setItem("new-registered-user", "yes");

    if (data && props.userAlreadyActivated) {
      await changeIdentity(data.registerPerson);

      await router.push({ name: RouteName.HOME });
    }
  });

  onError((err) => {
    errors.value = err.graphQLErrors.reduce(
      (acc: { [key: string]: string }, error: any) => {
        acc[error.details || error.field] = error.message;
        return acc;
      },
      {}
    );
    console.error("Error while registering person", err);
    console.error("Errors while registering person", errors);
    sendingValidation.value = false;
  });
};
</script>

<style lang="scss" scoped>
.avatar-enter-active {
  transition: opacity 1s ease;
}

.avatar-enter,
.avatar-leave-to {
  opacity: 0;
}

.avatar-leave {
  display: none;
}

.container .columns {
  margin: 1rem auto 3rem;
}

p.description {
  font-size: 0.9rem;
  margin-bottom: 15px;
  margin-top: -10px;
}
</style>
