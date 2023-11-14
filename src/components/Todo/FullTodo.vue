<template>
  <div class="card" v-if="todo">
    <div class="card-content">
      <o-field :label="$t('Status')">
        <o-checkbox size="large" v-model="status" />
      </o-field>
      <o-field :label="$t('Title')">
        <o-input v-model="title" />
      </o-field>
      <o-field :label="$t('Assigned to')"> </o-field>
      <o-field :label="$t('Due on')">
        <o-datepicker v-model="dueDate" :first-day-of-week="firstDayOfWeek" />
      </o-field>
    </div>
  </div>
</template>
<script lang="ts" setup>
import debounce from "lodash/debounce";
import { ITodo } from "../../types/todos";
import { UPDATE_TODO } from "../../graphql/todos";
import { Snackbar } from "@/plugins/snackbar";
import { computed, inject, ref } from "vue";
import { useMutation } from "@vue/apollo-composable";
import { Locale } from "date-fns";

const props = defineProps<{
  todo: ITodo;
}>();

const editMode = ref(false);

const title = computed({
  get(): string {
    return props.todo.title;
  },
  set(newTitle: string) {
    debounceUpdateTodo({ id: props.todo.id, title: newTitle });
  },
});

const status = computed({
  get(): boolean {
    return props.todo.status;
  },
  set(newStatus: boolean) {
    debounceUpdateTodo({ id: props.todo.id, status: newStatus });
  },
});

// const assignedTo = computed({
//   get(): IPerson | undefined {
//     return props.todo.assignedTo;
//   },
//   set(person: IPerson | undefined) {
//     debounceUpdateTodo({
//       id: props.todo.id,
//       assignedToId: person ? person.id : null,
//     });
//   },
// });

const dueDate = computed({
  get(): string | undefined {
    return props.todo.dueDate;
  },

  set(newDueDate: string | undefined) {
    debounceUpdateTodo({ id: props.todo.id, dueDate: newDueDate });
  },
});

const snackbar = inject<Snackbar>("snackbar");

const {
  mutate: updateTodo,
  onDone: updateTodoDone,
  onError: updateTodoError,
} = useMutation(UPDATE_TODO);

updateTodoDone(() => {
  editMode.value = false;
});

updateTodoError((e) => {
  snackbar?.open({
    message: e.message,
    variant: "danger",
    position: "bottom",
  });
});

const debounceUpdateTodo = debounce(updateTodo, 1000);

const dateFnsLocale = inject<Locale>("dateFnsLocale");

const firstDayOfWeek = computed((): number => {
  return dateFnsLocale?.options?.weekStartsOn ?? 0;
});
</script>
