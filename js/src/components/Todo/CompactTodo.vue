<template>
  <div class="card" v-if="todo">
    <div class="card-content">
      <b-checkbox v-model="status" />
      <router-link
        :to="{ name: RouteName.TODO, params: { todoId: todo.id } }"
        >{{ todo.title }}</router-link
      >
      <span class="details has-text-grey">
        <span v-if="todo.dueDate" class="due_date">
          <b-icon icon="calendar" />
          {{ todo.dueDate | formatDateString }}
        </span>
        <span v-if="todo.assignedTo" class="assigned_to">
          <b-icon icon="account" />
          {{ `@${todo.assignedTo.preferredUsername}` }}
          <span v-if="todo.assignedTo.domain">{{
            `@${todo.assignedTo.domain}`
          }}</span>
        </span>
      </span>
    </div>
  </div>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { SnackbarProgrammatic as Snackbar } from "buefy";
import { ITodo } from "../../types/todos";
import RouteName from "../../router/name";
import { UPDATE_TODO } from "../../graphql/todos";

@Component
export default class Todo extends Vue {
  @Prop({ required: true, type: Object }) todo!: ITodo;

  RouteName = RouteName;

  editMode = false;

  get status(): boolean {
    return this.todo.status;
  }

  set status(status: boolean) {
    this.updateTodo({ status });
  }

  async updateTodo(params: Record<string, unknown>): Promise<void> {
    try {
      await this.$apollo.mutate({
        mutation: UPDATE_TODO,
        variables: {
          id: this.todo.id,
          ...params,
        },
      });
      this.editMode = false;
    } catch (e) {
      Snackbar.open({
        message: e.message,
        type: "is-danger",
        position: "is-bottom",
      });
    }
  }
}
</script>
<style lang="scss" scoped>
span.details {
  margin-left: 1rem;
}
</style>
