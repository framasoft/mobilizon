# Documentation for developpers

_This file is a summary of the documentation for developpers. As explained in [CONTRIBUTING.md](../CONTRIBUTING.md), the main documentation is available at <https://docs.joinmobilizon.org/contribute/>_

## Technologies

Mobilizon is an app that uses:
  * [Elixir](https://elixir-lang.org/) for backend,
  * [VueJS](https://vuejs.org/) for front-end
  * [GraphQL](https://graphql.org/) as it's API layer

[GraphQL](https://graphql.org/) is managed using:
  * [Absinthe](https://absinthe-graphql.org/) on the backend
  * [VueApollo](https://apollo.vuejs.org/) on the front-end.
  
[UI](https://en.wikipedia.org/wiki/User_interface) is handled with [Tailwind](https://tailwindcss.com/) and [Oruga](https://oruga.io/).

## Structure of sources

  * `config` backend compile-time and runtime configuration
  * `docker` 🐳
  * `js/src` Front-end
  * `lib/federation` Handling all the federation stuff (sending and receving activities, converting activities, signatures, helpers…)
  * `lib/graphql/schema` The schema declarations for the GraphQL API
  * `lib/graphql/resolvers` The logic behind the GraphQL API
  * `lib/mix/tasks` CLI
  * `lib/mobilizon` model structures, database queries
  * `lib/service` various services
  * `lib/web` controllers, middlewares, auth-related stuff
  * `test` tests
