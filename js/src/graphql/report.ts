import gql from "graphql-tag";
import { ACTOR_FRAGMENT } from "./actor";

export const REPORTS = gql`
  query Reports(
    $status: ReportStatus
    $domain: String
    $page: Int
    $limit: Int
  ) {
    reports(status: $status, domain: $domain, page: $page, limit: $limit) {
      total
      elements {
        id
        reported {
          ...ActorFragment
          suspended
        }
        reporter {
          ...ActorFragment
          suspended
        }
        events {
          id
          uuid
          title
          picture {
            id
            url
          }
        }
        status
        content
      }
    }
  }
  ${ACTOR_FRAGMENT}
`;

const REPORT_FRAGMENT = gql`
  fragment ReportFragment on Report {
    id
    reported {
      ...ActorFragment
    }
    reporter {
      ...ActorFragment
    }
    events {
      id
      uuid
      title
      description
      beginsOn
      picture {
        id
        url
      }
      organizerActor {
        ...ActorFragment
      }
      attributedTo {
        ...ActorFragment
      }
    }
    comments {
      id
      text
      actor {
        ...ActorFragment
      }
      updatedAt
      deletedAt
      uuid
      event {
        id
        uuid
        title
      }
    }
    notes {
      id
      content
      moderator {
        ...ActorFragment
      }
      insertedAt
    }
    insertedAt
    updatedAt
    status
    content
  }
  ${ACTOR_FRAGMENT}
`;

export const REPORT = gql`
  query Report($id: ID!) {
    report(id: $id) {
      ...ReportFragment
    }
  }
  ${REPORT_FRAGMENT}
`;

export const CREATE_REPORT = gql`
  mutation CreateReport(
    $eventsIds: [ID]
    $reportedId: ID!
    $content: String
    $commentsIds: [ID]
    $forward: Boolean
  ) {
    createReport(
      eventsIds: $eventsIds
      reportedId: $reportedId
      content: $content
      commentsIds: $commentsIds
      forward: $forward
    ) {
      id
    }
  }
`;

export const UPDATE_REPORT = gql`
  mutation UpdateReport(
    $reportId: ID!
    $status: ReportStatus!
    $antispamFeedback: AntiSpamFeedback
  ) {
    updateReportStatus(
      reportId: $reportId
      status: $status
      antispamFeedback: $antispamFeedback
    ) {
      ...ReportFragment
    }
  }
  ${REPORT_FRAGMENT}
`;

export const CREATE_REPORT_NOTE = gql`
  mutation CreateReportNote($reportId: ID!, $content: String!) {
    createReportNote(reportId: $reportId, content: $content) {
      id
      content
      insertedAt
    }
  }
`;

export const LOGS = gql`
  query ActionLogs($page: Int, $limit: Int) {
    actionLogs(page: $page, limit: $limit) {
      elements {
        id
        action
        actor {
          ...ActorFragment
        }
        object {
          ... on Report {
            id
          }
          ... on ReportNote {
            report {
              id
            }
          }
          ... on Event {
            id
            title
          }
          ... on Comment {
            id
            text
            event {
              id
              title
              uuid
            }
            actor {
              ...ActorFragment
            }
          }
          ... on Person {
            ...ActorFragment
          }
          ... on Group {
            ...ActorFragment
          }
          ... on User {
            id
            email
            confirmedAt
          }
        }
        insertedAt
      }
      total
    }
  }
  ${ACTOR_FRAGMENT}
`;
