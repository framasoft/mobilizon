<template>
  <div class="container mx-auto" v-if="group">
    <breadcrumbs-nav
      :links="[
        {
          name: RouteName.GROUP,
          params: { preferredUsername: usernameWithDomain(group) },
          text: displayName(group),
        },
        {
          name: RouteName.TODO_LISTS,
          params: { preferredUsername: usernameWithDomain(group) },
          text: $t('Task lists'),
        },
      ]"
    />
    <section>
      <p>
        {{
          $t(
            "Create to-do lists for all the tasks you need to do, assign them and set due dates."
          )
        }}
      </p>
      <form
        class="form"
        @submit.prevent="
          createNewTodoList({
            title: newTodoList.title,
            groupId: group?.id,
          })
        "
      >
        <o-field :label="$t('List title')">
          <o-input v-model="newTodoList.title" />
        </o-field>
        <o-button native-type="submit">{{ $t("Create a new list") }}</o-button>
      </form>
      <div v-for="todoList in todoLists" :key="todoList.id">
        <router-link
          :to="{ name: RouteName.TODO_LIST, params: { id: todoList.id } }"
        >
          <h3>
            {{
              $t(
                "{title} ({count} todos)",
                {
                  count: todoList.todos.total,
                  title: todoList.title,
                },
                todoList.todos.total
              )
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
<script lang="ts" setup>
import { usernameWithDomain, displayName } from "@/types/actor";
import { CREATE_TODO_LIST } from "@/graphql/todos";
import CompactTodo from "@/components/Todo/CompactTodo.vue";
import { ITodoList } from "@/types/todolist";
import RouteName from "../../router/name";
import { useGroup } from "@/composition/apollo/group";
import { computed, reactive } from "vue";
import { useHead } from "@/utils/head";
import { useI18n } from "vue-i18n";
import { useMutation } from "@vue/apollo-composable";

const props = defineProps<{ preferredUsername: string }>();
const preferredUsername = computed(() => props.preferredUsername);

const { group } = useGroup(preferredUsername);

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() =>
    t("{group}'s todolists", { group: displayName(group.value) })
  ),
});

const newTodoList = reactive<ITodoList>({
  title: "",
  id: "",
  todos: { elements: [], total: 0 },
});

const todoLists = computed((): ITodoList[] => {
  return group.value?.todoLists.elements ?? [];
});

// const todoListsCount = computed((): number => {
//   return group.value?.todoLists.total ?? 0;
// });

const { mutate: createNewTodoList } = useMutation(CREATE_TODO_LIST);
</script>
