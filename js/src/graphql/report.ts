import gql from 'graphql-tag';

export const REPORTS = gql`
    query Reports($status: ReportStatus) {
        reports(status: $status) {
            id,
            reported {
                id,
                preferredUsername,
                name,
                avatar {
                    url
                }
            },
            reporter {
                id,
                preferredUsername,
                name,
                avatar {
                    url
                }
            },
            event {
                id,
                uuid,
                title,
                picture {
                    url
                }
            },
            status
        }
    }
`;

const REPORT_FRAGMENT = gql`
    fragment ReportFragment on Report {
        id,
        reported {
            id,
            preferredUsername,
            name,
            avatar {
                url
            }
        },
        reporter {
            id,
            preferredUsername,
            name,
            avatar {
                url
            }
        },
        event {
            id,
            uuid,
            title,
            description,
            picture {
                url
            }
        },
        notes {
            id,
            content
            moderator {
                preferredUsername,
                name,
                avatar {
                    url
                }
            },
            insertedAt
        },
        insertedAt,
        updatedAt,
        status,
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
        $eventId: ID!,
        $reporterActorId: ID!,
        $reportedActorId: ID!,
        $content: String
    ) {
        createReport(eventId: $eventId, reporterActorId: $reporterActorId, reportedActorId: $reportedActorId, content: $content) {
            id
        }
    }
    `;

export const UPDATE_REPORT = gql`
    mutation UpdateReport(
        $reportId: ID!,
        $moderatorId: ID!,
        $status: ReportStatus!
    ) {
        updateReportStatus(reportId: $reportId, moderatorId: $moderatorId, status: $status) {
            ...ReportFragment
        }
    }
    ${REPORT_FRAGMENT}
`;

export const CREATE_REPORT_NOTE = gql`
    mutation CreateReportNote(
        $reportId: ID!,
        $moderatorId: ID!,
        $content: String!
    ) {
        createReportNote(reportId: $reportId, moderatorId: $moderatorId, content: $content) {
            id,
            content,
            insertedAt
        }
    }
    `;

export const LOGS = gql`
    query {
        actionLogs {
            id,
            action,
            actor {
                id,
                preferredUsername
                avatar {
                    url
                }
            },
            object {
                ...on Report {
                    id
                },
                ... on ReportNote {
                    report {
                        id,
                    }
                }
                ... on Event {
                    id,
                    title
                }
            },
            insertedAt
        }
    }
    `;
