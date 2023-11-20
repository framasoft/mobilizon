<template>
  <div class="card" v-if="todo">
    <div class="card-content">
      <o-checkbox v-model="status" />
      <router-link
        :to="{ name: RouteName.TODO, params: { todoId: todo.id } }"
        >{{ todo.title }}</router-link
      >
      <span class="">
        <span v-if="todo.dueDate" class="">
          <o-icon icon="calendar" />
          {{ formatDateString(todo.dueDate) }}
        </span>
        <span v-if="todo.assignedTo" class="">
          <Account />
          <o-icon icon="account" />
          {{ `@${todo.assignedTo.preferredUsername}` }}
          <span v-if="todo.assignedTo.domain">{{
            `@${todo.assignedTo.domain}`
          }}</span>
        </span>
      </span>
    </div>
  </div>
</template>
<script lang="ts" setup>
import { ITodo } from "../../types/todos";
import RouteName from "../../router/name";
import { UPDATE_TODO } from "../../graphql/todos";
import { computed, inject, ref } from "vue";
import { useMutation } from "@vue/apollo-composable";
import Account from "vue-material-design-icons/Account.vue";
import { formatDateString } from "@/filters/datetime";
import { Snackbar } from "@/plugins/snackbar";

const props = defineProps<{ todo: ITodo }>();

const editMode = ref(false);

const status = computed({
  get() {
    return props.todo.status;
  },
  set(newStatus: boolean) {
    updateTodo({ status: newStatus, id: props.todo.id });
  },
});

const { mutate: updateTodo, onDone, onError } = useMutation(UPDATE_TODO);

onDone(() => {
  editMode.value = false;
});

const snackbar = inject<Snackbar>("snackbar");

onError((e) => {
  snackbar?.open({
    message: e.message,
    variant: "danger",
    position: "bottom",
  });
});
</script>
