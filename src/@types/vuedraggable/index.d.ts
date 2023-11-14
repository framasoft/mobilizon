declare module "vuedraggable" {
  import Vue, { ComponentOptions } from "vue";

  export interface DraggedContext<T> {
    index: number;
    futureIndex: number;
    element: T;
  }

  export interface DropContext<T> {
    index: number;
    component: Vue;
    element: T;
  }

  export interface Rectangle {
    top: number;
    right: number;
    bottom: number;
    left: number;
    width: number;
    height: number;
  }

  export interface MoveEvent<T> {
    originalEvent: DragEvent;
    dragged: Element;
    draggedContext: DraggedContext<T>;
    draggedRect: Rectangle;
    related: Element;
    relatedContext: DropContext<T>;
    relatedRect: Rectangle;
    from: Element;
    to: Element;
    willInsertAfter: boolean;
    isTrusted: boolean;
  }

  export interface ChangeEvent<T> {
    added: {
      newIndex: number;
      element: T;
    };
    removed: {
      oldIndex: number;
      element: T;
    };
    moved: {
      newIndex: number;
      oldIndex: number;
    };
  }

  const draggableComponent: ComponentOptions<Vue>;

  export default draggableComponent;
}
