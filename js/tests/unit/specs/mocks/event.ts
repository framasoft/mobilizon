import { EventJoinOptions, ParticipantRole } from "@/types/enums";

type DataMock = {
  data: Record<string, unknown>;
};

export const fetchEventBasicMock = {
  data: {
    event: {
      __typename: "Event",
      id: "1",
      uuid: "f37910ea-fd5a-4756-9679-00971f3f4106",
      joinOptions: EventJoinOptions.FREE,
      participantStats: {
        __typename: "ParticipantStats",
        notApproved: 0,
        notConfirmed: 0,
        rejected: 0,
        participant: 0,
        creator: 1,
        moderator: 0,
        administrator: 0,
        going: 1,
      },
    },
  },
};

export const joinEventResponseMock = {
  data: {
    joinEvent: {
      __typename: "Participant",
      id: "5",
      role: ParticipantRole.NOT_APPROVED,
      insertedAt: "2020-12-07T09:33:41Z",
      metadata: {
        __typename: "ParticipantMetadata",
        cancellationToken: "some token",
        message: "a message long enough",
      },
      event: {
        __typename: "Event",
        id: "1",
        uuid: "f37910ea-fd5a-4756-9679-00971f3f4106",
      },
      actor: {
        __typename: "Person",
        preferredUsername: "some_actor",
        name: "Some actor",
        avatar: null,
        domain: null,
        id: "1",
      },
    },
  },
};

export const joinEventMock = {
  eventId: "1",
  actorId: "1",
  email: "some@email.tld",
  message: "a message long enough",
  locale: "en_US",
};

export const eventCommentThreadsMock = {
  data: {
    event: {
      __typename: "Event",
      id: "1",
      uuid: "f37910ea-fd5a-4756-9679-00971f3f4106",
      comments: [
        {
          __typename: "Comment",
          id: "2",
          uuid: "e37910ea-fd5a-4756-9679-00971f3f4107",
          url: "https://some-instance.tld/comments/e37910ea-fd5a-4756-9679-00971f3f4107",
          text: "my comment text",
          local: true,
          visibility: "PUBLIC",
          totalReplies: 5,
          updatedAt: "2020-12-03T09:02:00Z",
          actor: {
            __typename: "Person",
            avatar: {
              __typename: "Media",
              id: "78",
              url: "http://someavatar.url.me",
            },
            id: "89",
            domain: null,
            preferredUsername: "someauthor",
            name: "Some author",
            summary: "I am the senate",
          },
          deletedAt: null,
        },
        {
          __typename: "Comment",
          id: "29",
          uuid: "e37910ea-fd5a-4756-9679-01171f3f4107",
          url: "https://some-instance.tld/comments/e37910ea-fd5a-4756-9679-01171f3f4107",
          text: "a second comment",
          local: true,
          visibility: "PUBLIC",
          totalReplies: 0,
          updatedAt: "2020-12-03T11:02:00Z",
          actor: {
            __typename: "Person",
            avatar: {
              __typename: "Media",
              id: "78",
              url: "http://someavatar.url.me",
            },
            id: "89",
            domain: null,
            preferredUsername: "someauthor",
            name: "Some author",
            summary: "I am the senate",
          },
          deletedAt: null,
        },
      ],
    },
  },
};

export const newCommentForEventMock = {
  eventId: "1",
  text: "my new comment",
  inReplyToCommentId: null,
};

export const newCommentForEventResponse: DataMock = {
  data: {
    createComment: {
      __typename: "Comment",
      id: "79",
      uuid: "e37910ea-fd5a-4756-9679-01171f3f4444",
      url: "https://some-instance.tld/comments/e37910ea-fd5a-4756-9679-01171f3f4444",
      text: newCommentForEventMock.text,
      local: true,
      visibility: "PUBLIC",
      totalReplies: 0,
      updatedAt: "2020-12-03T13:02:00Z",
      originComment: null,
      inReplyToComment: null,
      replies: [],
      actor: {
        __typename: "Person",
        avatar: {
          __typename: "Media",
          id: "78",
          url: "http://someavatar.url.me",
        },
        id: "89",
        domain: null,
        preferredUsername: "someauthor",
        name: "Some author",
        summary: "I am the senate",
      },
      deletedAt: null,
    },
  },
};
