<template>
  <div class="container section" v-if="group">
    <nav class="breadcrumb" aria-label="breadcrumbs">
      <ul>
        <li>
          <router-link
            :to="{
              name: RouteName.GROUP,
              params: { preferredUsername: usernameWithDomain(group) },
            }"
            >{{ group.name }}</router-link
          >
        </li>
        <li class="is-active">
          <router-link
            :to="{
              name: RouteName.TODO_LISTS,
              params: { preferredUsername: usernameWithDomain(group) },
            }"
            >{{ $t("Task lists") }}</router-link
          >
        </li>
      </ul>
    </nav>
    <section>
      <p>
        {{
          $t(
            "Create to-do lists for all the tasks you need to do, assign them and set due dates."
          )
        }}
      </p>
      <form class="form" @submit.prevent="createNewTodoList">
        <b-field :label="$t('List title')">
          <b-input v-model="newTodoList.title" />
        </b-field>
        <b-button native-type="submit">{{ $t("Create a new list") }}</b-button>
      </form>
      <div v-for="todoList in todoLists" :key="todoList.id">
        <router-link
          :to="{ name: RouteName.TODO_LIST, params: { id: todoList.id } }"
        >
          <h3 class="is-size-3">
            {{
              $tc("{title} ({count} todos)", todoList.todos.total, {
                count: todoList.todos.total,
                title: todoList.title,
              })
            }}
          </h3>
        </router-link>
        <compact-todo
          :todo="todo"
          v-for="todo in todoList.todos.elements"
          :key="todo.id"
        />
      </div>
    </section>
  </div>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { FETCH_GROUP } from "@/graphql/group";
import { IGroup, usernameWithDomain } from "@/types/actor";
import { CREATE_TODO_LIST } from "@/graphql/todos";
import CompactTodo from "@/components/Todo/CompactTodo.vue";
import { ITodoList } from "@/types/todolist";
import RouteName from "../../router/name";

@Component({
  apollo: {
    group: {
      query: FETCH_GROUP,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          name: this.$route.params.preferredUsername,
        };
      },
    },
  },
  components: {
    CompactTodo,
  },
})
export default class TodoLists extends Vue {
  @Prop({ type: String, required: true }) preferredUsername!: string;

  group!: IGroup;

  newTodoList: ITodoList = {
    title: "",
    id: "",
    todos: { elements: [], total: 0 },
  };

  RouteName = RouteName;

  usernameWithDomain = usernameWithDomain;

  get todoLists(): ITodoList[] {
    return this.group.todoLists.elements;
  }

  get todoListsCount(): number {
    return this.group.todoLists.total;
  }

  async createNewTodoList(): Promise<void> {
    await this.$apollo.mutate({
      mutation: CREATE_TODO_LIST,
      variables: {
        title: this.newTodoList.title,
        groupId: this.group.id,
      },
    });
  }
}
</script>
