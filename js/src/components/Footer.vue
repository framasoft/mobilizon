<template>
    <footer class="footer">
        <mobilizon-logo :invert="true" class="logo" />
        <img src="../assets/footer.png" :alt="$gettext('World map')" />
        <ul>
            <li><router-link :to="{ name: 'About'}"><translate>About</translate></router-link></li>
            <li><router-link :to="{ name: 'Licence'}"><translate>License</translate></router-link></li>
            <li><router-link :to="{ name: 'Legal'}"><translate>Legal</translate></router-link></li>
        </ul>
        <div class="content has-text-centered">
            <span
                    v-translate="{
            date: new Date().getFullYear(),
            }"
            >© The Mobilizon Contributors %{date} - Made with Elixir, Phoenix, VueJS & with some love and some weeks</span>
        </div>
    </footer>
</template>
<script lang="ts">
import { Component, Vue } from 'vue-property-decorator';
import Logo from './Logo.vue';

@Component({
  components: {
    'mobilizon-logo': Logo,
  },
})
export default class Footer extends Vue {
}
</script>
<style lang="scss" scoped>
    @import "../variables.scss";

    footer.footer {
        color: $secondary;
        display: flex;
        flex-direction: column;
        align-items: center;

        .logo {
            flex: 1;
        }

        div.content {
            flex: 1;
        }

        ul li {
            display: inline-flex;
            margin: auto 5px;

            a {
                color: #eee;
                font-size: 1.5rem;
                text-decoration: underline;
                text-decoration-color: $secondary;
            }
        }
    }
</style>
