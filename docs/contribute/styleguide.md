# Styleguide

## Elixir

We format our code with the Elixir Formatter and check for issues with [Credo](https://github.com/rrrene/credo) (a few rules are not blocking).

Please run these two commands before pushing code:

 * `mix format`
 * `mix credo --strict -a`
 
These two commands must not return an error code, since they are required to pass inside CI.

## Front-end

### Linting

We use `tslint` and `eslint` with the `airbnb` preset.
Errors should be reported when the development server is running or when building a production bundle `yarn run build`.

Please run the following command before pushing code `yarn run lint`.

This command must not return an error code, since it's required to pass inside CI.

We also try to follow the [official Vue.js style guide](https://vuejs.org/v2/style-guide/).

### Styleguide

We present the components used on Mobilizon's front-end here: https://framasoft.frama.io/mobilizon/frontend/. The documentation is builded through [Vue Styleguidist](https://vue-styleguidist.github.io/)
