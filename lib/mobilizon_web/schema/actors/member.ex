defmodule MobilizonWeb.Schema.Actors.MemberType do
  use Absinthe.Schema.Notation

  @desc """
  Represents a member of a group
  """
  object :member do
    field(:parent, :group, description: "Of which the profile is member")
    field(:person, :person, description: "Which profile is member of")
    field(:role, :integer, description: "The role of this membership")
    field(:approved, :boolean, description: "Whether this membership has been approved")
  end
end
