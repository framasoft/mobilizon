<template>
    <h3>
        <span>
            <slot />
        </span>
    </h3>
</template>
<script lang="ts">
import { Component, Vue } from 'vue-property-decorator';

@Component
export default class Subtitle extends Vue {
}
</script>
<style lang="scss" scoped>
    @import "@/variables.scss";

    h3 {
        display: block;
        margin: 15px 0 30px;

        span {
            background: $secondary;
            display: inline;
            padding: 3px 8px;
            color: #3A384C;
            font-family: "Liberation Sans", "Helvetica Neue", Roboto, Helvetica, Arial, serif;
            font-weight: 400;
            font-size: 32px;
        }
    }
</style>