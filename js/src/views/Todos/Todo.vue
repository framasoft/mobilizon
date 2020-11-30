<template>
  <section class="section container" v-if="todo">
    <nav class="breadcrumb" aria-label="breadcrumbs">
      <ul>
        <li>
          <router-link
            :to="{
              name: RouteName.GROUP,
              params: {
                preferredUsername: todo.todoList.actor.preferredUsername,
              },
            }"
            >{{ todo.todoList.actor.name }}</router-link
          >
        </li>
        <li>
          <router-link
            :to="{
              name: RouteName.TODO_LIST,
              params: { id: todo.todoList.id },
            }"
          >
            {{ todo.todoList.title }}
          </router-link>
        </li>
        <li class="is-active">
          <router-link :to="{ name: RouteName.TODO }" aria-current="page">
            {{ todo.title }}
          </router-link>
        </li>
      </ul>
    </nav>
    <full-todo :todo="todo" />
  </section>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { GET_TODO } from "@/graphql/todos";
import { ITodo } from "@/types/todos";
import FullTodo from "@/components/Todo/FullTodo.vue";
import RouteName from "../../router/name";

@Component({
  components: {
    FullTodo,
  },
  apollo: {
    todo: {
      query: GET_TODO,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          id: this.$route.params.todoId,
        };
      },
    },
  },
})
export default class Todo extends Vue {
  @Prop({ type: String, required: true }) todoId!: string;

  todo!: ITodo;

  RouteName = RouteName;
}
</script>
