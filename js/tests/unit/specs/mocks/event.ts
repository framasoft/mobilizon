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
          url:
            "https://some-instance.tld/comments/e37910ea-fd5a-4756-9679-00971f3f4107",
          text: "my comment text",
          local: true,
          visibility: "PUBLIC",
          totalReplies: 5,
          updatedAt: "2020-12-03T09:02:00Z",
          actor: {
            avatar: {
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
          url:
            "https://some-instance.tld/comments/e37910ea-fd5a-4756-9679-01171f3f4107",
          text: "a second comment",
          local: true,
          visibility: "PUBLIC",
          totalReplies: 0,
          updatedAt: "2020-12-03T11:02:00Z",
          actor: {
            avatar: {
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

export const newCommentForEventResponse = {
  data: {
    createComment: {
      id: "79",
      uuid: "e37910ea-fd5a-4756-9679-01171f3f4444",
      url:
        "https://some-instance.tld/comments/e37910ea-fd5a-4756-9679-01171f3f4444",
      text: newCommentForEventMock.text,
      local: true,
      visibility: "PUBLIC",
      totalReplies: 0,
      updatedAt: "2020-12-03T13:02:00Z",
      originComment: null,
      inReplyToComment: null,
      actor: {
        avatar: {
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
