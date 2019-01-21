import gql from 'graphql-tag';

export const FETCH_EVENT = gql`
    query($uuid:UUID!) {
        event(uuid: $uuid) {
            id,
            uuid,
            url,
            local,
            title,
            description,
            beginsOn,
            endsOn,
            status,
            visibility,
            thumbnail,
            large_image,
            publish_at,
            # online_address,
            # phone_address,
            organizerActor {
                avatarUrl,
                preferredUsername,
                name,
            },
            # attributedTo {
            #     # avatarUrl,
            #     preferredUsername,
            #     name,
            # },
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
        id,
        uuid,
        url,
        local,
        title,
        description,
        beginsOn,
        endsOn,
        status,
        visibility,
        thumbnail,
        large_image,
        publish_at,
        # online_address,
        # phone_address,
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
        participants {
            role,
            actor {
                preferredUsername,
                avatarUrl,
                name
            }
        }
    }
}
`;

export const CREATE_EVENT = gql`
    mutation CreateEvent(
        $title: String!,
        $description: String!,
        $organizerActorId: String!,
        $category: String!,
        $beginsOn: DateTime!
    ) {
        createEvent(
            title: $title,
            description: $description,
            beginsOn: $beginsOn,
            organizerActorId: $organizerActorId,
            category: $category
        ) {
            id,
            uuid,
            title
        }
}
`;

export const EDIT_EVENT = gql`
    mutation EditEvent(
        $title: String!,
        $description: String!,
        $organizerActorId: Int!,
        $categoryId: Int!
        ) {
    EditEvent(title: $title, description: $description, organizerActorId: $organizerActorId, categoryId: $categoryId) {
    uuid
    }
}
`;

export const JOIN_EVENT = gql`
    mutation JoinEvent(
        $uuid: String!,
        $username: String!    
    ) {
        joinEvent(
            uuid: $uuid,
            username: $username
        )
}
`;
