<template>
    <footer class="footer" ref="footer">
        <mobilizon-logo :invert="true" class="logo" />
        <img src="../assets/footer.png" :alt="$t('World map')" />
        <ul>
            <li><a href="https://joinmobilizon.org">{{ $t('About') }}</a></li>
            <li><a href="https://framagit.org/framasoft/mobilizon/blob/master/LICENSE">{{ $t('License') }}</a></li>
        </ul>
        <div class="content has-text-centered">
            <span>{{ $t('© The Mobilizon Contributors {date} - Made with Elixir, Phoenix, VueJS & with some love and some weeks', { date: new Date().getFullYear()}) }}</span>
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
            fill: $secondary;
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
