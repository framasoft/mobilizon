import type { IActor, IPerson } from "@/types/actor";
import { ITodoList } from "./todolist";

export interface ITodo {
  id?: string;
  title: string;
  status: boolean;
  dueDate?: Date;
  creator?: IActor;
  assignedTo?: IPerson;
  todoList?: ITodoList;
}
