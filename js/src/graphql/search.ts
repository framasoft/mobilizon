import gql from "graphql-tag";
import { ACTOR_FRAGMENT } from "./actor";
import { ADDRESS_FRAGMENT } from "./address";
import { EVENT_OPTIONS_FRAGMENT } from "./event_options";
import { TAG_FRAGMENT } from "./tags";

export const SEARCH_EVENTS_AND_GROUPS = gql`
  query SearchEventsAndGroups(
    $location: String
    $radius: Float
    $tags: String
    $term: String
    $type: EventType
    $beginsOn: DateTime
    $endsOn: DateTime
    $eventPage: Int
    $groupPage: Int
    $limit: Int
  ) {
    searchEvents(
      location: $location
      radius: $radius
      tags: $tags
      term: $term
      type: $type
      beginsOn: $beginsOn
      endsOn: $endsOn
      page: $eventPage
      limit: $limit
    ) {
      total
      elements {
        id
        title
        uuid
        beginsOn
        picture {
          id
          url
        }
        tags {
          ...TagFragment
        }
        physicalAddress {
          ...AdressFragment
        }
        organizerActor {
          ...ActorFragment
        }
        attributedTo {
          ...ActorFragment
        }
        options {
          ...EventOptions
        }
        __typename
      }
    }
    searchGroups(
      term: $term
      location: $location
      radius: $radius
      page: $groupPage
      limit: $limit
    ) {
      total
      elements {
        ...ActorFragment
        banner {
          id
          url
        }
        members(roles: "member,moderator,administrator,creator") {
          total
        }
        followers(approved: true) {
          total
        }
        physicalAddress {
          ...AdressFragment
        }
      }
    }
  }
  ${EVENT_OPTIONS_FRAGMENT}
  ${TAG_FRAGMENT}
  ${ADDRESS_FRAGMENT}
  ${ACTOR_FRAGMENT}
`;

export const SEARCH_PERSONS = gql`
  query SearchPersons($searchText: String!, $page: Int, $limit: Int) {
    searchPersons(term: $searchText, page: $page, limit: $limit) {
      total
      elements {
        ...ActorFragment
      }
    }
  }
  ${ACTOR_FRAGMENT}
`;

export const INTERACT = gql`
  query Interact($uri: String!) {
    interact(uri: $uri) {
      ... on Event {
        id
        title
        uuid
        beginsOn
        picture {
          id
          url
        }
        tags {
          slug
          title
        }
        __typename
      }
      ... on Group {
        ...ActorFragment
      }
    }
  }
  ${ACTOR_FRAGMENT}
`;
