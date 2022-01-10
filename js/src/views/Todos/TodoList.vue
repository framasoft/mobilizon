<template>
  <section class="container section" v-if="todoList">
    <breadcrumbs-nav
      :links="[
        {
          name: RouteName.GROUP,
          params: { preferredUsername: usernameWithDomain(todoList.actor) },
          text: displayName(group),
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
    <form class="form box" @submit.prevent="createNewTodo">
      <b-field>
        <b-checkbox v-model="newTodo.status" />
        <b-input expanded v-model="newTodo.title" />
      </b-field>
      <b-button native-type="submit">{{ $t("Add a todo") }}</b-button>
    </form>
  </section>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { ITodo } from "@/types/todos";
import { CREATE_TODO, FETCH_TODO_LIST } from "@/graphql/todos";
import CompactTodo from "@/components/Todo/CompactTodo.vue";
import { CURRENT_ACTOR_CLIENT } from "@/graphql/actor";
import { displayName, IActor, usernameWithDomain } from "@/types/actor";
import { ITodoList } from "@/types/todolist";
import RouteName from "../../router/name";
import { ApolloCache, FetchResult, InMemoryCache } from "@apollo/client/core";

@Component({
  components: {
    CompactTodo,
  },
  apollo: {
    todoList: {
      query: FETCH_TODO_LIST,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          id: this.$route.params.id,
        };
      },
    },
    currentActor: CURRENT_ACTOR_CLIENT,
  },
  metaInfo() {
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    const { todoList } = this;
    return {
      title: todoList.title,
    };
  },
})
export default class TodoList extends Vue {
  @Prop({ type: String, required: true }) id!: string;

  todoList!: ITodoList;

  currentActor!: IActor;

  newTodo: ITodo = { title: "", status: false };

  RouteName = RouteName;

  displayName = displayName;

  usernameWithDomain = usernameWithDomain;

  async createNewTodo(): Promise<void> {
    await this.$apollo.mutate({
      mutation: CREATE_TODO,
      variables: {
        title: this.newTodo.title,
        status: this.newTodo.status,
        todoListId: this.id,
      },
      update: (store: ApolloCache<InMemoryCache>, { data }: FetchResult) => {
        if (data == null) return;
        const cachedData = store.readQuery<{ todoList: ITodoList }>({
          query: FETCH_TODO_LIST,
          variables: { id: this.todoList.id },
        });
        if (cachedData == null) return;
        const { todoList } = cachedData;
        if (todoList === null) {
          console.error(
            "Cannot update event notes cache, because of null value."
          );
          return;
        }
        const newTodo: ITodo = data.createTodo;
        newTodo.creator = this.currentActor;

        todoList.todos.elements = todoList.todos.elements.concat([newTodo]);

        store.writeQuery({
          query: FETCH_TODO_LIST,
          variables: { id: this.todoList.id },
          data: { todoList },
        });
      },
    });
    this.newTodo = { title: "", status: false };
  }
}
</script>
