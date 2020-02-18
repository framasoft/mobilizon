import { Paginate } from "@/types/paginate";
import { IActor, IPerson } from "@/types/actor";

export interface ITodoList {
  id: string;
  title: string;
  todos: Paginate<ITodo>;
  actor?: IActor;
}

export interface ITodo {
  id?: string;
  title: string;
  status: boolean;
  dueDate?: Date;
  creator?: IActor;
  assignedTo?: IPerson;
  todoList?: ITodoList;
}
