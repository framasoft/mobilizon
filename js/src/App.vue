<template>
  <div id="mobilizon">
    <NavBar />
    <div v-if="config && config.demoMode">
      <b-message
        class="container"
        type="is-danger"
        :title="$t('Warning').toLocaleUpperCase()"
        closable
        aria-close-label="Close"
      >
        <p>
          {{ $t("This is a demonstration site to test Mobilizon.") }}
          <b>{{ $t("Please do not use it in any real way.") }}</b>
          {{
            $t(
              "This website isn't moderated and the data that you enter will be automatically destroyed every day at 00:01 (Paris timezone)."
            )
          }}
        </p>
      </b-message>
    </div>
    <error v-if="error" :error="error" />

    <main v-else>
      <transition name="fade" mode="out-in">
        <router-view />
      </transition>
    </main>
    <mobilizon-footer />
  </div>
</template>

<script lang="ts">
import { Component, Vue } from "vue-property-decorator";
import NavBar from "./components/NavBar.vue";
import {
  AUTH_ACCESS_TOKEN,
  AUTH_USER_EMAIL,
  AUTH_USER_ID,
  AUTH_USER_ROLE,
} from "./constants";
import {
  CURRENT_USER_CLIENT,
  UPDATE_CURRENT_USER_CLIENT,
} from "./graphql/user";
import Footer from "./components/Footer.vue";
import Logo from "./components/Logo.vue";
import { initializeCurrentActor } from "./utils/auth";
import { CONFIG } from "./graphql/config";
import { IConfig } from "./types/config.model";
import { ICurrentUser } from "./types/current-user.model";
import jwt_decode, { JwtPayload } from "jwt-decode";
import { refreshAccessToken } from "./apollo/utils";

@Component({
  apollo: {
    currentUser: CURRENT_USER_CLIENT,
    config: CONFIG,
  },
  components: {
    Logo,
    NavBar,
    error: () =>
      import(/* webpackChunkName: "editor" */ "./components/Error.vue"),
    "mobilizon-footer": Footer,
  },
  metaInfo() {
    return {
      titleTemplate: "%s | Mobilizon",
    };
  },
})
export default class App extends Vue {
  config!: IConfig;

  currentUser!: ICurrentUser;

  error: Error | null = null;

  online = true;

  interval: number | undefined = undefined;

  async created(): Promise<void> {
    if (await this.initializeCurrentUser()) {
      await initializeCurrentActor(this.$apollo.provider.defaultClient);
    }
  }

  errorCaptured(error: Error): void {
    this.error = error;
  }

  private async initializeCurrentUser() {
    const userId = localStorage.getItem(AUTH_USER_ID);
    const userEmail = localStorage.getItem(AUTH_USER_EMAIL);
    const accessToken = localStorage.getItem(AUTH_ACCESS_TOKEN);
    const role = localStorage.getItem(AUTH_USER_ROLE);

    if (userId && userEmail && accessToken && role) {
      return this.$apollo.mutate({
        mutation: UPDATE_CURRENT_USER_CLIENT,
        variables: {
          id: userId,
          email: userEmail,
          isLoggedIn: true,
          role,
        },
      });
    }
    return false;
  }

  mounted(): void {
    this.online = window.navigator.onLine;
    window.addEventListener("offline", () => {
      this.online = false;
      this.showOfflineNetworkWarning();
      console.debug("offline");
    });
    window.addEventListener("online", () => {
      this.online = true;
      console.debug("online");
    });
    document.addEventListener("refreshApp", (event: Event) => {
      this.$buefy.snackbar.open({
        queue: false,
        indefinite: true,
        type: "is-primary",
        actionText: this.$t("Update app") as string,
        cancelText: this.$t("Ignore") as string,
        message: this.$t("A new version is available.") as string,
        onAction: async () => {
          // eslint-disable-next-line @typescript-eslint/ban-ts-comment
          // @ts-ignore
          const detail = event.detail;
          const registration = detail as ServiceWorkerRegistration;
          try {
            await this.refreshApp(registration);
            window.location.reload();
          } catch (err) {
            console.error(err);
            this.$notifier.error(
              this.$t(
                "An error has occured while refreshing the page."
              ) as string
            );
          }
        },
      });
    });

    this.interval = setInterval(async () => {
      const accessToken = localStorage.getItem(AUTH_ACCESS_TOKEN);
      if (accessToken) {
        const token = jwt_decode<JwtPayload>(accessToken);
        if (
          token?.exp !== undefined &&
          new Date(token.exp * 1000 - 60000) < new Date()
        ) {
          refreshAccessToken(this.$apollo.getClient());
        }
      }
    }, 60000);
  }

  private async refreshApp(
    registration: ServiceWorkerRegistration
  ): Promise<any> {
    const worker = registration.waiting;
    if (!worker) {
      return Promise.resolve();
    }
    console.debug("Doing worker.skipWaiting().");
    return new Promise((resolve, reject) => {
      const channel = new MessageChannel();

      channel.port1.onmessage = (event) => {
        console.debug("Done worker.skipWaiting().");
        if (event.data.error) {
          reject(event.data);
        } else {
          resolve(event.data);
        }
      };
      console.debug("calling skip waiting");
      worker?.postMessage({ type: "skip-waiting" }, [channel.port2]);
    });
  }

  showOfflineNetworkWarning(): void {
    this.$notifier.error(this.$t("You are offline") as string);
  }

  unmounted(): void {
    clearInterval(this.interval);
    this.interval = undefined;
  }
}
</script>

<style lang="scss">
@import "variables";

/* Icons */
$mdi-font-path: "~@mdi/font/fonts";
@import "~@mdi/font/scss/materialdesignicons";

@import "common";

#mobilizon {
  min-height: 100vh;
  display: flex;
  flex-direction: column;

  main {
    flex-grow: 1;
  }
}
</style>
