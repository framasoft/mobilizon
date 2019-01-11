import gql from 'graphql-tag';

export const FETCH_EVENT = gql`
    query($uuid:UUID!) {
        event(uuid: $uuid) {
            uuid,
            url,
            local,
            title,
            description,
            begins_on,
            ends_on,
            state,
            status,
            public,
            thumbnail,
            large_image,
            publish_at,
            # address_type,
            # online_address,
            # phone,
            organizerActor {
                avatarUrl,
                preferredUsername,
                name,
            },
            attributedTo {
                avatarUrl,
                preferredUsername,
                name,
            },
            participants {
                actor {
                    avatarUrl,
                    preferredUsername,
                    name,
                },
                role,
            },
            category {
                title,
            },
        }
        }
`;

export const FETCH_EVENTS = gql`
    query {
        events {
        uuid,
        url,
        local,
        title,
        description,
        begins_on,
        ends_on,
        state,
        status,
        public,
        thumbnail,
        large_image,
        publish_at,
        # address_type,
        # online_address,
        # phone,
        organizerActor {
            avatarUrl,
            preferredUsername,
            name,
        },
        attributedTo {
            avatarUrl,
            preferredUsername,
            name,
        },
        category {
            title,
        },
        }
    }
`;

export const CREATE_EVENT = gql`
    mutation CreateEvent(
        $title: String!,
        $description: String!,
        $organizerActorId: Int!,
        $categoryId: Int!,
        $beginsOn: DateTime!,
        $addressType: AddressType!,
    ) {
        createEvent(
            title: $title,
            description: $description,
            beginsOn: $beginsOn,
            organizerActorId: $organizerActorId,
            categoryId: $categoryId,
            addressType: $addressType) {
                uuid,
                title,
                description,
    }
}
`;

export const EDIT_EVENT = gql`
    mutation EditEvent(
        $title: String!,
        $description: String!,
        $organizerActorId: Int!,
        $categoryId: Int!,
        ) {
    EditEvent(title: $title, description: $description, organizerActorId: $organizerActorId, categoryId: $categoryId) {
    uuid
    }
}
`;
