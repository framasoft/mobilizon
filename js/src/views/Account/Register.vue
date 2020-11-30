<template>
  <section class="section container">
    <div class="columns is-mobile is-centered">
      <div class="column is-half-desktop">
        <h1 class="title" v-if="userAlreadyActivated">
          {{ $t("Congratulations, your account is now created!") }}
        </h1>
        <h1 class="title" v-else>
          {{
            $t("Register an account on {instanceName}!", {
              instanceName: config.name,
            })
          }}
        </h1>
        <p class="content" v-if="userAlreadyActivated">
          {{ $t("Now, create your first profile:") }}
        </p>
        <form v-if="!validationSent" @submit.prevent="submit">
          <b-field :label="$t('Displayed nickname')">
            <b-input
              aria-required="true"
              required
              v-model="identity.name"
              @input="autoUpdateUsername($event)"
            />
          </b-field>

          <b-field
            :label="$t('Username')"
            :type="errors.preferred_username ? 'is-danger' : null"
            :message="errors.preferred_username"
          >
            <b-field
              :message="
                $t(
                  'Only alphanumeric lowercased characters and underscores are supported.'
                )
              "
            >
              <b-input
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
            </b-field>
          </b-field>
          <p class="description">
            {{
              $t(
                "This identifier is unique to your profile. It allows others to find you."
              )
            }}
          </p>

          <b-field :label="$t('Short bio')">
            <b-input
              type="textarea"
              maxlength="100"
              rows="2"
              v-model="identity.summary"
            />
          </b-field>

          <p class="content">
            {{
              $t(
                "You will be able to add an avatar and set other options in your account settings."
              )
            }}
          </p>

          <p class="control has-text-centered">
            <b-button
              type="is-primary"
              size="is-large"
              native-type="submit"
              :disabled="sendingValidation"
              >{{ $t("Create my profile") }}</b-button
            >
          </p>
        </form>

        <div v-if="validationSent && !userAlreadyActivated">
          <b-message type="is-success" :closable="false">
            <h2 class="title">
              {{
                $t("Your account is nearly ready, {username}", {
                  username: identity.name || identity.preferredUsername,
                })
              }}
            </h2>
            <i18n path="A validation email was sent to {email}" tag="p">
              <code slot="email">{{ email }}</code>
            </i18n>
            <p>
              {{
                $t(
                  "Before you can login, you need to click on the link inside it to validate your account."
                )
              }}
            </p>
          </b-message>
        </div>
      </div>
    </div>
  </section>
</template>

<script lang="ts">
import { Component, Prop } from "vue-property-decorator";
import { mixins } from "vue-class-component";
import { CONFIG } from "@/graphql/config";
import { IConfig } from "@/types/config.model";
import { IPerson } from "../../types/actor";
import { IDENTITIES, REGISTER_PERSON } from "../../graphql/actor";
import { MOBILIZON_INSTANCE_HOST } from "../../api/_entrypoint";
import RouteName from "../../router/name";
import { changeIdentity } from "../../utils/auth";
import identityEditionMixin from "../../mixins/identityEdition";

@Component({
  apollo: {
    config: CONFIG,
  },
})
export default class Register extends mixins(identityEditionMixin) {
  @Prop({ type: String, required: true }) email!: string;

  @Prop({ type: Boolean, required: false, default: false })
  userAlreadyActivated!: boolean;

  config!: IConfig;

  host?: string = MOBILIZON_INSTANCE_HOST;

  errors: Record<string, unknown> = {};

  validationSent = false;

  sendingValidation = false;

  async created(): Promise<void> {
    // Make sure no one goes to this page if we don't want to
    if (!this.email) {
      await this.$router.replace({ name: RouteName.PAGE_NOT_FOUND });
    }
  }

  async submit(): Promise<void> {
    try {
      this.sendingValidation = true;
      this.errors = {};
      const { data } = await this.$apollo.mutate<{ registerPerson: IPerson }>({
        mutation: REGISTER_PERSON,
        variables: { email: this.email, ...this.identity },
        update: (store, { data: localData }) => {
          if (this.userAlreadyActivated) {
            const identitiesData = store.readQuery<{ identities: IPerson[] }>({
              query: IDENTITIES,
            });

            if (identitiesData && localData) {
              identitiesData.identities.push(localData.registerPerson);
              store.writeQuery({ query: IDENTITIES, data: identitiesData });
            }
          }
        },
      });
      if (data) {
        this.validationSent = true;
        window.localStorage.setItem("new-registered-user", "yes");

        if (this.userAlreadyActivated) {
          await changeIdentity(
            this.$apollo.provider.defaultClient,
            data.registerPerson
          );

          await this.$router.push({ name: RouteName.HOME });
        }
      }
    } catch (errorCatched) {
      this.errors = errorCatched.graphQLErrors.reduce(
        (acc: { [key: string]: string }, error: any) => {
          acc[error.details || error.field] = error.message;
          return acc;
        },
        {}
      );
      console.error("Error while registering person", errorCatched);
      console.error("Errors while registering person", this.errors);
      this.sendingValidation = false;
    }
  }
}
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

section.section {
  background: $white;
}
</style>
