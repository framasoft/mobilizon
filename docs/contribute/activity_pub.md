# Federation

## ActivityPub

Mobilizon uses [ActivityPub](http://activitypub.rocks/) to federate content between instances. It only supports the server-to-server part of [the ActivityPub spec](https://www.w3.org/TR/activitypub/).

It implements the [HTTP signatures spec](https://tools.ietf.org/html/draft-cavage-http-signatures-12) for authentication of inbox deliveries, but doesn't implement Linked Data Signatures for forwarded payloads, and instead fetches content when needed.

To match usernames to actors, Mobilizon uses [WebFinger](https://tools.ietf.org/html/rfc7033).

## Instance subscriptions

Instances subscribe to each other through an internal actor named `relay@instance.tld` that publishes (through `Announce`) every created content to it's followers. Each content creation share is saved so that updates and deletes are correctly sent to every relay subscriber.

## Activities

Supported Activity | Supported Object
------------ | -------------
`Accept` | `Follow`, `Join`  
`Announce` | `Object`
`Create` | `Note`, `Event`
`Delete` | `Object`
`Flag` | `Object`
`Follow` | `Object`  
`Reject` | `Follow`, `Join`
`Remove` | `Note`, `Event`
`Undo` | `Announce`, `Follow`
`Update` | `Object`  

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