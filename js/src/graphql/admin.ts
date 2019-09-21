import gql from 'graphql-tag';

export const DASHBOARD = gql`
    query {
        dashboard {
            lastPublicEventPublished {
                title,
                picture {
                    alt
                    url
                },
            },
            numberOfUsers,
            numberOfEvents,
            numberOfComments,
            numberOfReports
        }
    }
    `;
