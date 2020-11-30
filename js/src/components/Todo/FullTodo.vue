<template>
  <div class="card" v-if="todo">
    <div class="card-content">
      <b-field :label="$t('Status')">
        <b-checkbox size="is-large" v-model="status" />
      </b-field>
      <b-field :label="$t('Title')">
        <b-input v-model="title" />
      </b-field>
      <b-field :label="$t('Assigned to')">
        <actor-auto-complete v-model="assignedTo" />
      </b-field>
      <b-field :label="$t('Due on')">
        <b-datepicker v-model="dueDate" />
      </b-field>
    </div>
  </div>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { debounce, DebouncedFunc } from "lodash";
import { SnackbarProgrammatic as Snackbar } from "buefy";
import { ITodo } from "../../types/todos";
import RouteName from "../../router/name";
import { UPDATE_TODO } from "../../graphql/todos";
import ActorAutoComplete from "../Account/ActorAutoComplete.vue";
import { IPerson } from "../../types/actor";

@Component({
  components: { ActorAutoComplete },
})
export default class Todo extends Vue {
  @Prop({ required: true, type: Object }) todo!: ITodo;

  RouteName = RouteName;

  editMode = false;

  debounceUpdateTodo!: DebouncedFunc<
    (obj: Record<string, unknown>) => Promise<void>
  >;

  // We put this in data because of issues like
  // https://github.com/vuejs/vue-class-component/issues/263
  data(): Record<string, unknown> {
    return {
      debounceUpdateTodo: debounce(this.updateTodo, 1000),
    };
  }

  get title(): string {
    return this.todo.title;
  }

  set title(title: string) {
    this.debounceUpdateTodo({ title });
  }

  get status(): boolean {
    return this.todo.status;
  }

  set status(status: boolean) {
    this.debounceUpdateTodo({ status });
  }

  get assignedTo(): IPerson | undefined {
    return this.todo.assignedTo;
  }

  set assignedTo(person: IPerson | undefined) {
    this.debounceUpdateTodo({ assignedToId: person ? person.id : null });
  }

  get dueDate(): Date | undefined {
    return this.todo.dueDate;
  }

  set dueDate(dueDate: Date | undefined) {
    this.debounceUpdateTodo({ dueDate });
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
