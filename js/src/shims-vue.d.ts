import { Vue } from 'vue/types/vue';

declare module '*.vue' {
  import Vue from 'vue';
  export default Vue;
}

type Refs<T extends object> = Vue['$refs'] & T;
