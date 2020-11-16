<template>
  <div class="container section">
    <h2 class="title">{{ $t("Glossary") }}</h2>
    <div class="content" v-if="config">
      <p>
        {{
          $t(
            "Some terms, technical or otherwise, used in the text below may cover concepts that are difficult to grasp. We have provided a glossary here to help you understand them better:"
          )
        }}
      </p>
      <dl>
        <dt>{{ $t("Instance") }}</dt>
        <i18n
          tag="dd"
          path="An instance is an installed version of the Mobilizon software running on a server. An instance can be run by anyone using the {mobilizon_software} or other federated apps, aka the “fediverse”. This instance's name is {instance_name}. Mobilizon is a federated network of multiple instances (just like email servers), users registered on different instances may communicate even though they didn't register on the same instance."
        >
          <a slot="mobilizon_software" href="https://joinmobilizon.org">{{
            $t("Mobilizon software")
          }}</a>
          <b slot="instance_name">{{ config.name }}</b>
        </i18n>
        <dt>{{ $t("Instance administrator") }}</dt>
        <dd>
          {{
            $t(
              "The instance administrator is the person or entity that runs this Mobilizon instance."
            )
          }}
        </dd>
        <dt>{{ $t("Application") }}</dt>
        <dd>
          {{
            $t(
              "In the following context, an application is a software, either provided by the Mobilizon team or by a 3rd-party, used to interact with your instance."
            )
          }}
        </dd>
        <dt>{{ $t("API") }}</dt>
        <dd>
          {{
            $t(
              "An “application programming interface” or “API” is a communication protocol that allows software components to communicate with each other. The Mobilizon API, for example, can allow third-party software tools to communicate with Mobilizon instances to carry out certain actions, such as posting events on your behalf, automatically and remotely."
            )
          }}
        </dd>
        <dt>{{ $t("SSL/TLS") }}</dt>
        <i18n
          tag="dd"
          path="SSL and it's successor TLS are encryption technologies to secure data communications when using the service. You can recognize an encrypted connection in your browser's address line when the URL begins with {https} and the lock icon is displayed in your browser's address bar."
        >
          <code slot="https">https://</code>
        </i18n>
        <dt>{{ $t("Cookies and Local storage") }}</dt>
        <dd>
          {{
            $t(
              "A cookie is a small file containing information that is sent to your computer when you visit a website. When you visit the site again, the cookie allows that site to recognize your browser. Cookies may store user preferences and other information. You can configure your browser to refuse all cookies. However, this may result in some website features or services partially working. Local storage works the same way but allows you to store more data."
            )
          }}
        </dd>
      </dl>
    </div>
  </div>
</template>

<script lang="ts">
import { Component, Vue } from "vue-property-decorator";
import { ABOUT } from "../../graphql/config";
import { IConfig } from "../../types/config.model";

@Component({
  apollo: {
    config: ABOUT,
  },
})
export default class Glossary extends Vue {
  config!: IConfig;
}
</script>

<style lang="scss" scoped>
::v-deep dt {
  font-weight: bold;
}
</style>
