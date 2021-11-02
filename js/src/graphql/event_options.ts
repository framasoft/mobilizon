import gql from "graphql-tag";

export const EVENT_OPTIONS_FRAGMENT = gql`
  fragment EventOptions on EventOptions {
    maximumAttendeeCapacity
    remainingAttendeeCapacity
    showRemainingAttendeeCapacity
    anonymousParticipation
    showStartTime
    showEndTime
    timezone
    offers {
      price
      priceCurrency
      url
    }
    participationConditions {
      title
      content
      url
    }
    attendees
    program
    commentModeration
    showParticipationPrice
    hideOrganizerWhenGroupEvent
    isOnline
  }
`;
