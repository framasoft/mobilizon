<template>
  <section class="section container" v-if="todo">
    <breadcrumbs-nav
      :links="[
        {
          name: RouteName.GROUP,
          params: {
            preferredUsername: usernameWithDomain(todo.todoList.actor),
          },
          text: displayName(todo.todoList.actor),
        },
        {
          name: RouteName.TODO_LISTS,
          params: {
            preferredUsername: usernameWithDomain(todo.todoList.actor),
          },
          text: $t('Task lists'),
        },
        {
          name: RouteName.TODO_LIST,
          params: { id: todo.todoList.id },
          text: todo.todoList.title,
        },
        { name: RouteName.TODO, text: todo.title },
      ]"
    />
    <full-todo :todo="todo" />
  </section>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { GET_TODO } from "@/graphql/todos";
import { ITodo } from "@/types/todos";
import FullTodo from "@/components/Todo/FullTodo.vue";
import RouteName from "../../router/name";
import { displayName, usernameWithDomain } from "@/types/actor";

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
  metaInfo() {
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    const { todo } = this;
    return {
      title: todo.title,
    };
  },
})
export default class Todo extends Vue {
  @Prop({ type: String, required: true }) todoId!: string;

  todo!: ITodo;

  RouteName = RouteName;

  usernameWithDomain = usernameWithDomain;

  displayName = displayName;
}
</script>
