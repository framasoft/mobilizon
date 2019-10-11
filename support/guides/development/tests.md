# Tests

## Backend

The backend uses `ExUnit`.

To launch all the tests:
```bash
mix test
```

If you want test coverage:

```bash
mix coveralls.html
```

It will show the coverage and will output a `cover/excoveralls.html` file.

If you want to test a single file:

```bash
mix test test/mobilizon/actors/actors_test.exs
```

If you want to test a specific test, block or line:

```bash
mix test test/mobilizon/actors/actors_test.exs:85
```

> Note: The coveralls.html also works the same

## Front-end

### Unit tests

Not done yet.

### End-to-end tests

We use [Cypress](https://cypress.io) for End-to-end testing.

When inside the `js` directory, you can do either
```bash
npx cypress run
```
to run the tests, or
```bash
npx cypress open
```
to open the interactive GUI.

Cypress provided [a subscription](https://www.cypress.io/oss-plan) to their recording dashboard since Mobilizon is an Open-Source project. Thanks!