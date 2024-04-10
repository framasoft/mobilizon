<template>
  <section class="container mx-auto" v-if="todo">
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
<script lang="ts" setup>
import { GET_TODO } from "@/graphql/todos";
import { ITodo } from "@/types/todos";
import FullTodo from "@/components/Todo/FullTodo.vue";
import RouteName from "../../router/name";
import { displayName, usernameWithDomain } from "@/types/actor";
import { useQuery } from "@vue/apollo-composable";
import { useHead } from "@/utils/head";
import { computed } from "vue";

const props = defineProps<{ todoId: string }>();

const { result: todoResult } = useQuery<{ todo: ITodo }>(GET_TODO, () => ({
  id: props.todoId,
}));

const todo = computed(() => todoResult.value?.todo);

useHead({
  title: computed(() => todo.value?.title),
});
</script>
