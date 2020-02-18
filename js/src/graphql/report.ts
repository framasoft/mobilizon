import gql from "graphql-tag";

export const REPORTS = gql`
  query Reports($status: ReportStatus) {
    reports(status: $status) {
      id
      reported {
        id
        preferredUsername
        domain
        name
        avatar {
          url
        }
      }
      reporter {
        id
        preferredUsername
        name
        avatar {
          url
        }
        domain
        type
      }
      event {
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
`;

const REPORT_FRAGMENT = gql`
  fragment ReportFragment on Report {
    id
    reported {
      id
      preferredUsername
      name
      avatar {
        url
      }
      domain
    }
    reporter {
      id
      preferredUsername
      name
      avatar {
        url
      }
      domain
      type
    }
    event {
      id
      uuid
      title
      description
      picture {
        id
        url
      }
    }
    comments {
      id
      text
      actor {
        id
        preferredUsername
        domain
        name
        avatar {
          url
        }
      }
    }
    notes {
      id
      content
      moderator {
        id
        preferredUsername
        name
        avatar {
          url
        }
      }
      insertedAt
    }
    insertedAt
    updatedAt
    status
    content
  }
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
    $eventId: ID!
    $reporterId: ID!
    $reportedId: ID!
    $content: String
    $commentsIds: [ID]
    $forward: Boolean
  ) {
    createReport(
      eventId: $eventId
      reporterId: $reporterId
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
  mutation UpdateReport($reportId: ID!, $moderatorId: ID!, $status: ReportStatus!) {
    updateReportStatus(reportId: $reportId, moderatorId: $moderatorId, status: $status) {
      ...ReportFragment
    }
  }
  ${REPORT_FRAGMENT}
`;

export const CREATE_REPORT_NOTE = gql`
  mutation CreateReportNote($reportId: ID!, $moderatorId: ID!, $content: String!) {
    createReportNote(reportId: $reportId, moderatorId: $moderatorId, content: $content) {
      id
      content
      insertedAt
    }
  }
`;

export const LOGS = gql`
  query {
    actionLogs {
      id
      action
      actor {
        id
        preferredUsername
        avatar {
          url
        }
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
      }
      insertedAt
    }
  }
`;
