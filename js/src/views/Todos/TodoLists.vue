<template>
  <div class="container section" v-if="group">
    <nav class="breadcrumb" aria-label="breadcrumbs">
      <ul>
        <li>
          <router-link
            :to="{ name: RouteName.GROUP, params: { preferredUsername: group.preferredUsername } }"
            >{{ group.preferredUsername }}</router-link
          >
        </li>
        <li class="is-active">
          <router-link
            :to="{
              name: RouteName.TODO_LISTS,
              params: { preferredUsername: group.preferredUsername },
            }"
            >{{ $t("Task lists") }}</router-link
          >
        </li>
      </ul>
    </nav>
    <section>
      <form class="form" @submit.prevent="createNewTodoList">
        <b-field :label="$t('List title')">
          <b-input v-model="newTodoList.title" />
        </b-field>
        <b-button native-type="submit">{{ $t("Create a new list") }}</b-button>
      </form>
      <div v-for="todoList in todoLists" :key="todoList.id">
        <router-link :to="{ name: RouteName.TODO_LIST, params: { id: todoList.id } }">
          <h3 class="is-size-3">
            {{
              $tc("{title} ({count} todos)", todoList.todos.total, {
                count: todoList.todos.total,
                title: todoList.title,
              })
            }}
          </h3>
        </router-link>
        <compact-todo :todo="todo" v-for="todo in todoList.todos.elements" :key="todo.id" />
      </div>
    </section>
  </div>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { FETCH_GROUP } from "@/graphql/group";
import { IGroup } from "@/types/actor";
import { ITodoList } from "@/types/todos";
import { CREATE_TODO_LIST } from "@/graphql/todos";
import CompactTodo from "@/components/Todo/CompactTodo.vue";
import RouteName from "../../router/name";

@Component({
  apollo: {
    group: {
      query: FETCH_GROUP,
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

  get todoLists() {
    return this.group.todoLists.elements;
  }

  get todoListsCount() {
    return this.group.todoLists.total;
  }

  async createNewTodoList() {
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
