defmodule Mobilizon.Repo.Migrations.ChangeActorsIndexes do
  use Ecto.Migration

  def up do
    drop(
      index("actors", [:preferred_username, :domain],
        name: :actors_preferred_username_domain_index
      )
    )

    drop(index("actors", [:name, :domain], name: :accounts_username_domain_index))
    execute("ALTER INDEX accounts_pkey RENAME TO actors_pkey")
    create(index("actors", [:preferred_username, :domain, :type], unique: true))
    create(index("actors", [:url], unique: true))
  end

  def down do
    create(
      index("actors", [:preferred_username, :domain],
        name: :actors_preferred_username_domain_index
      )
    )

    create(index("actors", [:name, :domain], name: :accounts_username_domain_index))
    execute("ALTER INDEX actors_pkey RENAME TO accounts_pkey")
    drop(index("actors", [:preferred_username, :domain, :type]))
    drop(index("actors", [:url]))
  end
end
