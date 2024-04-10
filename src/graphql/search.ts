import gql from "graphql-tag";
import { ACTOR_FRAGMENT } from "./actor";
import { ADDRESS_FRAGMENT } from "./address";
import { EVENT_OPTIONS_FRAGMENT } from "./event_options";
import { TAG_FRAGMENT } from "./tags";

export const GROUP_RESULT_FRAGMENT = gql`
  fragment GroupResultFragment on GroupSearchResult {
    id
    avatar {
      id
      url
    }
    type
    preferredUsername
    name
    domain
    summary
    url
  }
`;

export const SEARCH_EVENTS_AND_GROUPS = gql`
  query SearchEventsAndGroups(
    $location: String
    $radius: Float
    $tags: String
    $term: String
    $type: EventType
    $categoryOneOf: [String]
    $statusOneOf: [EventStatus]
    $languageOneOf: [String]
    $searchTarget: SearchTarget
    $beginsOn: DateTime
    $endsOn: DateTime
    $longevents: Boolean
    $bbox: String
    $zoom: Int
    $eventPage: Int
    $groupPage: Int
    $limit: Int
    $sortByEvents: SearchEventSortOptions
    $sortByGroups: SearchGroupSortOptions
    $boostLanguages: [String]
  ) {
    searchEvents(
      location: $location
      radius: $radius
      tags: $tags
      term: $term
      type: $type
      categoryOneOf: $categoryOneOf
      statusOneOf: $statusOneOf
      languageOneOf: $languageOneOf
      searchTarget: $searchTarget
      beginsOn: $beginsOn
      endsOn: $endsOn
      longevents: $longevents
      bbox: $bbox
      zoom: $zoom
      page: $eventPage
      limit: $limit
      sortBy: $sortByEvents
      boostLanguages: $boostLanguages
    ) {
      total
      elements {
        id
        title
        uuid
        beginsOn
        endsOn
        picture {
          id
          url
        }
        url
        status
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
        participantStats {
          participant
        }
        options {
          isOnline
        }
        __typename
      }
    }
    searchGroups(
      term: $term
      location: $location
      radius: $radius
      languageOneOf: $languageOneOf
      searchTarget: $searchTarget
      bbox: $bbox
      zoom: $zoom
      page: $groupPage
      limit: $limit
      sortBy: $sortByGroups
      boostLanguages: $boostLanguages
    ) {
      total
      elements {
        __typename
        id
        avatar {
          id
          url
        }
        type
        preferredUsername
        name
        domain
        summary
        url
        ...GroupResultFragment
        banner {
          id
          url
        }
        followersCount
        membersCount
        physicalAddress {
          ...AdressFragment
        }
      }
    }
  }
  ${TAG_FRAGMENT}
  ${ADDRESS_FRAGMENT}
  ${GROUP_RESULT_FRAGMENT}
  ${ACTOR_FRAGMENT}
`;

export const SEARCH_EVENTS = gql`
  query SearchEvents(
    $location: String
    $radius: Float
    $tags: String
    $term: String
    $type: EventType
    $category: String
    $beginsOn: DateTime
    $endsOn: DateTime
    $eventPage: Int
    $limit: Int
    $longevents: Boolean
  ) {
    searchEvents(
      location: $location
      radius: $radius
      tags: $tags
      term: $term
      type: $type
      category: $category
      beginsOn: $beginsOn
      endsOn: $endsOn
      page: $eventPage
      limit: $limit
      longevents: $longevents
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
        status
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
  }
  ${EVENT_OPTIONS_FRAGMENT}
  ${TAG_FRAGMENT}
  ${ADDRESS_FRAGMENT}
  ${ACTOR_FRAGMENT}
`;

export const SEARCH_CALENDAR_EVENTS = gql`
  query SearchEvents(
    $beginsOn: DateTime
    $endsOn: DateTime
    $eventPage: Int
    $limit: Int
  ) {
    searchEvents(
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
        endsOn
        picture {
          id
          url
        }
        status
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
  }
  ${EVENT_OPTIONS_FRAGMENT}
  ${TAG_FRAGMENT}
  ${ADDRESS_FRAGMENT}
  ${ACTOR_FRAGMENT}
`;

export const SEARCH_GROUPS = gql`
  query SearchGroups(
    $location: String
    $radius: Float
    $term: String
    $groupPage: Int
    $limit: Int
  ) {
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
        membersCount
        followersCount
        physicalAddress {
          ...AdressFragment
        }
      }
    }
  }
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

export const SEARCH_PERSON_AND_GROUPS = gql`
  query SearchPersonsAndGroups($searchText: String!, $page: Int, $limit: Int) {
    searchPersons(term: $searchText, page: $page, limit: $limit) {
      total
      elements {
        ...ActorFragment
      }
    }
    searchGroups(term: $searchText, page: $page, limit: $limit) {
      total
      elements {
        ...ActorFragment
        banner {
          id
          url
        }
        membersCount
        followersCount
        physicalAddress {
          ...AdressFragment
        }
      }
    }
  }
  ${ADDRESS_FRAGMENT}
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
        status
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
