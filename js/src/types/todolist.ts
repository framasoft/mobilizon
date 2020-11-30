import type { IActor } from "./actor";
import type { Paginate } from "./paginate";
import type { ITodo } from "./todos";

export interface ITodoList {
  id: string;
  title: string;
  todos: Paginate<ITodo>;
  actor?: IActor;
}
