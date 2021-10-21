defmodule Mobilizon.Service.Metadata.InstanceTest do
  alias Mobilizon.Config
  alias Mobilizon.Service.Metadata.{Instance, Utils}
  alias Mobilizon.Web.Endpoint
  use Mobilizon.DataCase

  describe "build_tags/0 for the instance" do
    test "gives tags" do
      title = "#{Config.instance_name()} - Mobilizon"
      description = Utils.process_description(Config.instance_description())

      assert Instance.build_tags() |> Utils.stringify_tags() ==
               """
               <title>#{title}</title><meta content="#{description}" name="description"><meta content="#{title}" property="og:title"><meta content="#{Endpoint.url()}" property="og:url"><meta content="#{description}" property="og:description"><meta content="website" property="og:type"><script type="application/ld+json">{"@context":"http://schema.org","@type":"WebSite","name":"#{title}","potentialAction":{"@type":"SearchAction","query-input":"required name=search_term","target":"#{Endpoint.url()}/search?term={search_term}"},"url":"#{Endpoint.url()}"}</script>
               """
    end
  end
end
