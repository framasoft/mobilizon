import gql from "graphql-tag";

export const GET_TODO = gql`
  query GetTodo($id: ID!) {
    todo(id: $id) {
      id
      title
      status
      dueDate
      todoList {
        actor {
          id
          preferredUsername
          domain
          name
        }
        title
        id
      }
      assignedTo {
        id
        preferredUsername
        domain
        name
        avatar {
          id
          url
        }
      }
    }
  }
`;

export const FETCH_TODO_LIST = gql`
  query FetchTodoList($id: ID!) {
    todoList(id: $id) {
      id
      title
      todos {
        total
        elements {
          id
          title
          status
          assignedTo {
            id
            preferredUsername
            domain
          }
          dueDate
        }
      }
      actor {
        id
        preferredUsername
        domain
        name
      }
    }
  }
`;

export const CREATE_TODO_LIST = gql`
  mutation CreateTodoList($title: String!, $groupId: ID!) {
    createTodoList(title: $title, groupId: $groupId) {
      id
      title
      todos {
        total
        elements {
          id
        }
      }
    }
  }
`;

export const CREATE_TODO = gql`
  mutation createTodo(
    $title: String!
    $todoListId: ID!
    $status: Boolean
    $assignedToId: ID
    $dueDate: DateTime
  ) {
    createTodo(
      title: $title
      todoListId: $todoListId
      status: $status
      assignedToId: $assignedToId
      dueDate: $dueDate
    ) {
      id
      title
      status
      assignedTo {
        id
      }
      creator {
        id
      }
      dueDate
    }
  }
`;

export const UPDATE_TODO = gql`
  mutation updateTodo(
    $id: ID!
    $title: String
    $status: Boolean
    $assignedToId: ID
    $dueDate: DateTime
  ) {
    updateTodo(
      id: $id
      title: $title
      status: $status
      assignedToId: $assignedToId
      dueDate: $dueDate
    ) {
      id
      title
      status
      assignedTo {
        id
      }
      creator {
        id
      }
      dueDate
    }
  }
`;
