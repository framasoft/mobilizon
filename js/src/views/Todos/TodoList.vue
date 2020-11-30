<template>
  <section class="container section" v-if="todoList">
    <nav class="breadcrumb" aria-label="breadcrumbs">
      <ul>
        <li>
          <router-link
            :to="{
              name: RouteName.GROUP,
              params: { preferredUsername: todoList.actor.preferredUsername },
            }"
            >{{ todoList.actor.name }}</router-link
          >
        </li>
        <li>
          <router-link
            :to="{
              name: RouteName.TODO_LISTS,
              params: { preferredUsername: todoList.actor.preferredUsername },
            }"
            >{{ $t("Task lists") }}</router-link
          >
        </li>
        <li class="is-active">
          <router-link
            :to="{ name: RouteName.TODO_LIST, params: { id: todoList.id } }"
          >
            {{ todoList.title }}
          </router-link>
        </li>
      </ul>
    </nav>
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
import { IActor } from "@/types/actor";
import { ITodoList } from "@/types/todolist";
import RouteName from "../../router/name";

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
})
export default class TodoList extends Vue {
  @Prop({ type: String, required: true }) id!: string;

  todoList!: ITodoList;

  currentActor!: IActor;

  newTodo: ITodo = { title: "", status: false };

  RouteName = RouteName;

  async createNewTodo(): Promise<void> {
    await this.$apollo.mutate({
      mutation: CREATE_TODO,
      variables: {
        title: this.newTodo.title,
        status: this.newTodo.status,
        todoListId: this.id,
      },
      update: (store, { data }) => {
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
