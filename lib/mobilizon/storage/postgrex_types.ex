Postgrex.Types.define(
  Mobilizon.Storage.PostgresTypes,
  [Geo.PostGIS.Extension | Ecto.Adapters.Postgres.extensions()],
  json: Jason
)
