# Styleguide

# Elixir

We format our code with the Elixir Formatter and check for issues with [Credo](https://github.com/rrrene/credo) (a few rules are not blocking).

Please run those two commands before pushing code :
 * `mix format`
 * `mix credo`
 
These two commands must not return an error code, since they are required to pass inside CI.

# Front

We use `tslint` with the `tslint-config-airbnb` preset.
Errors should be reported when running in dev mode `npm run dev` or when building a production bundle `npm run build`.

We also try to follow the [official Vue.js style guide](https://vuejs.org/v2/style-guide/).
