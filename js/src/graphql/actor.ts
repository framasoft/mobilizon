import gql from 'graphql-tag';

export const FETCH_ACTOR = gql`
query($name:String!) {
  actor(preferredUsername: $name) {
    url,
    outboxUrl,
    inboxUrl,
    followingUrl,
    followersUrl,
    sharedInboxUrl,
    name,
    domain,
    summary,
    preferredUsername,
    suspended,
    avatarUrl,
    bannerUrl,
    organizedEvents {
        uuid,
        title,
        description,
        organizer_actor {
            avatarUrl,
            preferred_username,
            name,
        }
    },
  }
}
`;

export const LOGGED_ACTOR = gql`
query {
  loggedActor {
    avatarUrl,
    preferredUsername,
  }
}`;
