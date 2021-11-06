import gql from "graphql-tag";
import { ACTOR_FRAGMENT } from "./actor";
import { ADDRESS_FRAGMENT } from "./address";
import { EVENT_OPTIONS_FRAGMENT } from "./event_options";
import { TAG_FRAGMENT } from "./tags";
import { USER_SETTINGS_FRAGMENT } from "./user";

export const HOME_USER_QUERIES = gql`
  query HomeUserQueries(
    $afterDateTime: DateTime
    $beforeDateTime: DateTime
    $page: Int
    $limit: Int
  ) {
    loggedUser {
      id
      locale
      settings {
        ...UserSettingFragment
      }
      participations(
        afterDatetime: $afterDateTime
        beforeDatetime: $beforeDateTime
        page: $page
        limit: $limit
      ) {
        total
        elements {
          event {
            id
            uuid
            title
            picture {
              id
              url
              alt
            }
            beginsOn
            visibility
            organizerActor {
              ...ActorFragment
            }
            attributedTo {
              ...ActorFragment
            }
            participantStats {
              going
              notApproved
              participant
            }
            options {
              ...EventOptions
            }
            tags {
              ...TagFragment
            }
          }
          id
          role
          actor {
            ...ActorFragment
          }
        }
      }
      followedGroupEvents {
        total
        elements {
          profile {
            id
          }
          group {
            ...ActorFragment
          }
          event {
            id
            uuid
            title
            beginsOn
            picture {
              url
            }
            attributedTo {
              ...ActorFragment
            }
            organizerActor {
              ...ActorFragment
            }
            options {
              ...EventOptions
            }
            physicalAddress {
              ...AdressFragment
            }
            tags {
              ...TagFragment
            }
          }
        }
      }
    }
  }
  ${USER_SETTINGS_FRAGMENT}
  ${ADDRESS_FRAGMENT}
  ${TAG_FRAGMENT}
  ${EVENT_OPTIONS_FRAGMENT}
  ${ACTOR_FRAGMENT}
`;

export const CLOSE_CONTENT = gql`
  query CloseContent(
    $location: String!
    $radius: Float
    $page: Int
    $limit: Int
  ) {
    searchEvents(
      location: $location
      radius: $radius
      page: $page
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
        options {
          ...EventOptions
        }
        physicalAddress {
          ...AdressFragment
        }
        attributedTo {
          ...ActorFragment
        }
        organizerActor {
          ...ActorFragment
        }
        __typename
      }
    }
  }
  ${ADDRESS_FRAGMENT}
  ${TAG_FRAGMENT}
  ${EVENT_OPTIONS_FRAGMENT}
  ${ACTOR_FRAGMENT}
`;
