import gql from 'graphql-tag';

export const COMMENT_FIELDS_FRAGMENT_NAME = 'CommentFields';
export const COMMENT_FIELDS_FRAGMENT = gql`
    fragment CommentFields on Comment {
        id,
        uuid,
        url,
        text,
        visibility,
        local,
        actor {
            avatar {
                url
            },
            id,
            domain,
            preferredUsername,
            name
        },
        totalReplies,
        updatedAt,
        deletedAt
    },
`;

export const COMMENT_RECURSIVE_FRAGMENT = gql`
    fragment CommentRecursive on Comment {
        ...CommentFields
        inReplyToComment {
            ...CommentFields
        },
        originComment {
            ...CommentFields
        },
        replies {
            ...CommentFields
            replies {
                ...CommentFields
            }
        },
    },
    ${COMMENT_FIELDS_FRAGMENT}
`;

export const FETCH_THREAD_REPLIES = gql`
    query($threadId: ID!) {
        thread(id: $threadId) {
            ...CommentRecursive
        }
    }
    ${COMMENT_RECURSIVE_FRAGMENT}
`;


export const COMMENTS_THREADS = gql`
    query($eventUUID: UUID!) {
        event(uuid: $eventUUID) {
            id,
            uuid,
            comments {
                ...CommentFields,
            }
        }
    }
    ${COMMENT_RECURSIVE_FRAGMENT}
`;

export const CREATE_COMMENT_FROM_EVENT = gql`
    mutation CreateCommentFromEvent($eventId: ID!, $actorId: ID!, $text: String!, $inReplyToCommentId: ID) {
        createComment(eventId: $eventId, actorId: $actorId, text: $text, inReplyToCommentId: $inReplyToCommentId) {
            ...CommentRecursive
        }
    }
    ${COMMENT_RECURSIVE_FRAGMENT}
`;


export const DELETE_COMMENT = gql`
    mutation DeleteComment($commentId: ID!, $actorId: ID!) {
        deleteComment(commentId: $commentId, actorId: $actorId) {
            id
        }
    }
`;
