# Federation

## ActivityPub

Mobilizon uses [ActivityPub](http://activitypub.rocks/) to federate content between instances. It only supports the server-to-server part of [the ActivityPub spec](https://www.w3.org/TR/activitypub/).

It implements the [HTTP signatures spec](https://tools.ietf.org/html/draft-cavage-http-signatures-12) for authentication of inbox deliveries, but doesn't implement Linked Data Signatures for forwarded payloads, and instead fetches content when needed.

To match usernames to actors, Mobilizon uses [WebFinger](https://tools.ietf.org/html/rfc7033).

## Instance subscriptions

Instances subscribe to each other through an internal actor named `relay@instance.tld` that publishes (through `Announce`) every created content to it's followers. Each content creation share is saved so that updates and deletes are correctly sent to every relay subscriber.

## Activities

Supported Activity | Supported Object or Activity
------------ | -------------
`Accept` | `Follow`, `Join` 
`Add` | `Document`, `ResourceCollection`
`Announce` | any `Object`
`Create` | any `Object`
`Delete` | any `Object`
`Flag` | any `Object`
`Follow` | any `Object`
`Invite` | `Group`
`Join` | `Event`
`Leave` | `Event`, `Group`
`Reject` | `Follow`, `Join`
`Remove` | `Note`, `Event`, `Member`
`Undo` | `Announce`, `Follow`
`Update` | `Object`

## Objects

### Person

Every Mobilizon profile is a [`Person`](https://www.w3.org/TR/activitystreams-vocabulary/#dfn-person).

### Event

Every Mobilizon event is an [`Event`](https://www.w3.org/TR/activitystreams-vocabulary/#dfn-event) with [a few extensions](#event_1), especially for location information since [`Place`](https://www.w3.org/TR/activitystreams-vocabulary/#dfn-place) is limited.

### Note

Every Mobilizon comment showing under an event is a [`Note`](https://www.w3.org/TR/activitystreams-vocabulary/#dfn-note), as well as every element from group discussions, where the [`context` property](https://www.w3.org/TR/activitystreams-vocabulary/#dfn-context) is used to group messages in discussions.

### Group

Every Mobilizon group is a [`Group`](https://www.w3.org/TR/activitystreams-vocabulary/#dfn-group).

### Member

Every Mobilizon group member is a `Member`, that conveys the role information that the `Person` has in the `Group`.

```json
%{
  "type" => "Member",
  "id" => "https://somemobilizon.instance/member/some-uuid",
  "actor" => "https://somemobilizon.instance/@some-person",
  "object" => "https://somemobilizon.instance/@some-group",
  "role" => "MODERATOR"
    }
```

The allowed values for `role` are: `invited`, `not_approved`, `member`, `moderator`, `administrator`, `rejected`.

### Document

Attached pictures and other files are represented with [`Document`](https://www.w3.org/TR/activitystreams-vocabulary/#dfn-document).

Group resources are also represented with `Document`.

### Article

Every Mobilizon group post is an [Article](https://www.w3.org/TR/activitystreams-vocabulary/#dfn-article).

### ResourceCollection

Mobilizon's group resources (see [Document](#Document)) can be collected into folders named `ResourceCollection`, which have the same set of properties as a `Document`, without the `url`.


## Extensions

### Event

The vocabulary for Event is based on [the Event object in ActivityStreams](https://www.w3.org/TR/activitystreams-vocabulary/#dfn-event), extended with :

* the [Event Schema](https://schema.org/Event) from Schema.org
* some properties from [iCalendar](https://tools.ietf.org/html/rfc5545), such as `ical:status` (see [this issue](https://framagit.org/framasoft/mobilizon/issues/320))

The following properties are added.

#### repliesModeration

Disabling replies is [an ongoing issue with ActivityPub](https://github.com/w3c/activitypub/issues/319) so we use a temporary property.

See [the corresponding issue](https://framagit.org/framasoft/mobilizon/issues/321).

Accepted values: `allow_all`, `closed`, `moderated` (not used at the moment)

!!! info
    We also support PeerTube's `commentEnabled` property as a fallback. It is set to `true` only when `repliesModeration` is equal to `allow_all`.

Example:
```json
{
  "@context": [
    "...",
    {
      "mz": "https://joinmobilizon.org/ns#",
      "pt": "https://joinpeertube.org/ns#",
      "repliesModerationOption": {
        "@id": "mz:repliesModerationOption",
        "@type": "mz:repliesModerationOptionType"
      },
      "repliesModerationOptionType": {
        "@id": "mz:repliesModerationOptionType",
        "@type": "rdfs:Class"
      },
      "commentsEnabled": {
        "@id": "pt:commentsEnabled",
        "@type": "sc:Boolean"
      }
    }
  ],
  "...": "...",
  "repliesModerationOption": "allow_all",
  "commentsEnabled": true,
  "type": "Event",
  "url": "http://mobilizon1.com/events/8cf76e9f-c426-4912-9cd6-c7030b969611"
}
```


#### joinMode

Indicator of how new members may be able to join.

See [the corresponding issue](https://framagit.org/framasoft/mobilizon/issues/321).

Accepted values: `free`, `restricted`, `invite` (not used at the moment)

Example:
```json
{
  "@context": [
    "...",
    {
      "mz": "https://joinmobilizon.org/ns#",
      "joinMode": {
        "@id": "mz:joinMode",
        "@type": "mz:joinModeType"
      },
      "joinModeType": {
        "@id": "mz:joinModeType",
        "@type": "rdfs:Class"
      }
    }
  ],
  "...": "...",
  "joinMode": "restricted",
  "type": "Event",
  "url": "http://mobilizon1.com/events/8cf76e9f-c426-4912-9cd6-c7030b969611"
}
```

#### location

We use Schema.org's `location` property on `Event`.
[The ActivityStream vocabulary to represent places](https://www.w3.org/TR/activitystreams-vocabulary/#places) is quite limited so instead of just using `Place` from ActivityStreams we also add a few properties from Schema.org's `Place` vocabulary.

We add [an `address` property](https://schema.org/address), which we assume to be [of `PostalAddress` type](https://schema.org/PostalAddress).

```json
{
  "@context": [
    "...",
    {
      "PostalAddress": "sc:PostalAddress",
      "address": {
        "@id": "sc:address",
        "@type": "sc:PostalAddress"
      },
      "addressCountry": "sc:addressCountry",
      "addressLocality": "sc:addressLocality",
      "addressRegion": "sc:addressRegion",
      "postalCode": "sc:postalCode",
      "sc": "http://schema.org#",
      "streetAddress": "sc:streetAddress",
    }
  ],
  "id": "http://mobilizon2.com/events/945f350d-a3e6-4bcd-9bf2-0bd2e4d353c5",
  "location": {
      "address": {
        "addressCountry": "France",
        "addressLocality": "Lyon",
        "addressRegion": "Auvergne-Rhône-Alpes",
        "postalCode": "69007",
        "streetAddress": "10 Rue Jangot",
        "type": "PostalAddress"
      },
      "latitude": 4.8425657,
      "longitude": 45.7517141,
      "id": "http://mobilizon2.com/address/bdf7fb53-7177-46f3-8fb3-93c25a802522",
      "name": "10 Rue Jangot",
      "type": "Place"
    },
  "type": "Event"
}
```





#### maximumAttendeeCapacity

We use Schema.org's [`maximumAttendeeCapacity`](https://schema.org/maximumAttendeeCapacity) to know how many places there can be for an event.

#### anonymousParticipationEnabled

We add this boolean field to know whether or not anonymous participants can participate to an event.

!!! note
    Even though this information is federated, we redirect anonymous participants to the original instance so they can participate.

### Join

#### participationMessage

We add a `participationMessage` property on a `Join` activity so that participants may transmit a note to event organizers, to motivate their participation when event participations are manually approved. This field is restricted to plain text.

```json
{
  "type": "Join",
  "object": "http://mobilizon.test/events/some-uuid",
  "id": "http://mobilizon2.test/@admin/join/event/1",
  "actor": "http://mobilizon2.test/@admin",
  "participationMessage": "I want to join !",
  "@context": [
    {
      "participationMessage": {
        "@id": "mz:participationMessage",
        "@type": "sc:Text"
      }
    }
  ]
}
```