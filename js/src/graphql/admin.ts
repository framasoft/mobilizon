import gql from 'graphql-tag';

export const DASHBOARD = gql`
    query {
        dashboard {
            lastPublicEventPublished {
                uuid,
                title,
                picture {
                    id,
                    alt,
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

export const RELAY_FRAGMENT = gql`
    fragment relayFragment on Follower {
        actor {
            id,
            preferredUsername,
            name,
            domain,
            type,
            summary
        },
        targetActor {
            id,
            preferredUsername,
            name,
            domain,
            type,
            summary
        },
        approved,
        insertedAt,
        updatedAt
    }
`;

export const RELAY_FOLLOWERS = gql`
    query relayFollowers($page: Int, $limit: Int) {
        relayFollowers(page: $page, limit: $limit) {
            elements {
                ...relayFragment
            },
            total
        }
    }
    ${RELAY_FRAGMENT}
`;

export const RELAY_FOLLOWINGS = gql`
    query relayFollowings($page: Int, $limit: Int) {
        relayFollowings(page: $page, limit: $limit) {
            elements {
                ...relayFragment
            },
            total
        }
    }
    ${RELAY_FRAGMENT}
`;

export const ADD_RELAY = gql`
    mutation addRelay($address: String!) {
        addRelay(address: $address) {
            ...relayFragment
        }
    }
    ${RELAY_FRAGMENT}
`;

export const REMOVE_RELAY = gql`
    mutation removeRelay($address: String!) {
        removeRelay(address: $address) {
            ...relayFragment
        }
    }
    ${RELAY_FRAGMENT}
`;

export const ACCEPT_RELAY = gql`
    mutation acceptRelay($address: String!) {
        acceptRelay(address: $address) {
            ...relayFragment
        }
    }
    ${RELAY_FRAGMENT}
`;

export const REJECT_RELAY = gql`
    mutation rejectRelay($address: String!) {
        rejectRelay(address: $address) {
            ...relayFragment
        }
    }
    ${RELAY_FRAGMENT}
`;
