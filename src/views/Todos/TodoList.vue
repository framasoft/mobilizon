<template>
  <section class="container mx-auto" v-if="todoList">
    <breadcrumbs-nav
      :links="[
        {
          name: RouteName.GROUP,
          params: { preferredUsername: usernameWithDomain(todoList.actor) },
          text: groupDisplayName,
        },
        {
          name: RouteName.TODO_LISTS,
          params: { preferredUsername: usernameWithDomain(todoList.actor) },
          text: $t('Task lists'),
        },
        {
          name: RouteName.TODO_LIST,
          params: { id: todoList.id },
          text: todoList.title,
        },
      ]"
    />
    <h2 class="title">{{ todoList.title }}</h2>
    <div v-for="todo in todoList.todos.elements" :key="todo.id">
      <compact-todo :todo="todo" />
    </div>
    <form
      class="form box"
      @submit.prevent="
        createNewTodo({
          title: newTodo.title,
          status: newTodo.status,
          todoListId: props.id,
        })
      "
    >
      <o-field>
        <o-checkbox v-model="newTodo.status" />
        <o-input expanded v-model="newTodo.title" />
      </o-field>
      <o-button native-type="submit">{{ $t("Add a todo") }}</o-button>
    </form>
  </section>
</template>
<script lang="ts" setup>
import { ITodo } from "@/types/todos";
import { CREATE_TODO, FETCH_TODO_LIST } from "@/graphql/todos";
import CompactTodo from "@/components/Todo/CompactTodo.vue";
import { displayName, usernameWithDomain } from "@/types/actor";
import { ITodoList } from "@/types/todolist";
import RouteName from "../../router/name";
import { ApolloCache, FetchResult, InMemoryCache } from "@apollo/client/core";
import { useMutation, useQuery } from "@vue/apollo-composable";
import { useCurrentActorClient } from "@/composition/apollo/actor";
import { useHead } from "@unhead/vue";
import { computed, ref } from "vue";

const props = defineProps<{ id: string }>();

const { currentActor } = useCurrentActorClient();

const { result: totoListResult } = useQuery<{ todoList: ITodoList }>(
  FETCH_TODO_LIST,
  () => ({
    id: props.id,
  })
);

const todoList = computed(() => totoListResult.value?.todoList);

const groupDisplayName = computed(() => displayName(todoList.value?.actor));

useHead({
  title: computed(() => todoList.value?.title ?? ""),
});

const newTodo = ref<ITodo>({ title: "", status: false });

const { mutate: createNewTodo, onDone } = useMutation(CREATE_TODO, () => ({
  update: (store: ApolloCache<InMemoryCache>, { data }: FetchResult) => {
    if (data == null) return;
    const cachedData = store.readQuery<{ todoList: ITodoList }>({
      query: FETCH_TODO_LIST,
      variables: { id: todoList.value?.id },
    });
    if (cachedData == null) return;
    const { todoList: todoListCached } = cachedData;
    if (todoListCached === null) {
      console.error("Cannot update event notes cache, because of null value.");
      return;
    }
    const newTodoCached: ITodo = data.createTodo;
    newTodoCached.creator = currentActor.value;

    todoListCached.todos.elements = todoListCached.todos.elements.concat([
      newTodoCached,
    ]);

    store.writeQuery({
      query: FETCH_TODO_LIST,
      variables: { id: todoListCached.id },
      data: { todoListCached },
    });
  },
}));

onDone(() => {
  newTodo.value = { title: "", status: false };
});
</script>
