import gql from "graphql-tag";
import { TAG_FRAGMENT } from "./tags";

export const POST_FRAGMENT = gql`
  fragment PostFragment on Post {
    id
    title
    slug
    url
    body
    draft
    author {
      id
      preferredUsername
      name
      domain
      avatar {
        id
        url
      }
    }
    attributedTo {
      id
      preferredUsername
      name
      domain
      avatar {
        id
        url
      }
    }
    insertedAt
    updatedAt
    publishAt
    draft
    visibility
    tags {
      ...TagFragment
    }
    picture {
      id
      url
      name
    }
  }
  ${TAG_FRAGMENT}
`;

export const POST_BASIC_FIELDS = gql`
  fragment PostBasicFields on Post {
    id
    title
    slug
    url
    author {
      id
      preferredUsername
      name
      domain
      avatar {
        id
        url
      }
    }
    attributedTo {
      id
      preferredUsername
      name
      domain
      avatar {
        id
        url
      }
    }
    insertedAt
    updatedAt
    publishAt
    draft
    visibility
    picture {
      id
      url
      name
    }
  }
`;

export const FETCH_GROUP_POSTS = gql`
  query GroupPosts($preferredUsername: String!, $page: Int, $limit: Int) {
    group(preferredUsername: $preferredUsername) {
      id
      preferredUsername
      domain
      name
      posts(page: $page, limit: $limit) {
        total
        elements {
          ...PostBasicFields
        }
      }
    }
  }
  ${POST_BASIC_FIELDS}
`;

export const FETCH_POST = gql`
  query Post($slug: String!) {
    post(slug: $slug) {
      ...PostFragment
    }
  }
  ${POST_FRAGMENT}
`;

export const CREATE_POST = gql`
  mutation CreatePost(
    $title: String!
    $body: String
    $attributedToId: ID!
    $visibility: PostVisibility
    $draft: Boolean
    $tags: [String]
    $picture: MediaInput
  ) {
    createPost(
      title: $title
      body: $body
      attributedToId: $attributedToId
      visibility: $visibility
      draft: $draft
      tags: $tags
      picture: $picture
    ) {
      ...PostFragment
    }
  }
  ${POST_FRAGMENT}
`;

export const UPDATE_POST = gql`
  mutation UpdatePost(
    $id: ID!
    $title: String
    $body: String
    $attributedToId: ID
    $visibility: PostVisibility
    $draft: Boolean
    $tags: [String]
    $picture: MediaInput
  ) {
    updatePost(
      id: $id
      title: $title
      body: $body
      attributedToId: $attributedToId
      visibility: $visibility
      draft: $draft
      tags: $tags
      picture: $picture
    ) {
      ...PostFragment
    }
  }
  ${POST_FRAGMENT}
`;

export const DELETE_POST = gql`
  mutation DeletePost($id: ID!) {
    deletePost(id: $id) {
      id
    }
  }
`;
