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

Waiting for [https://framagit.org/framasoft/mobilizon/merge_requests/42](https://framagit.org/framasoft/mobilizon/merge_requests/42) to be ready.
