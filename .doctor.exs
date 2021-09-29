%Doctor.Config{
  exception_moduledoc_required: true,
  failed: false,
  ignore_modules: [Mobilizon.Web, Mobilizon.GraphQL.Schema, Mobilizon.Service.Activity.Renderer, Mobilizon.Service.Workers.Helper],
  ignore_paths: [],
  min_module_doc_coverage: 100,
  min_module_spec_coverage: 50,
  min_overall_doc_coverage: 100,
  min_overall_spec_coverage: 90,
  moduledoc_required: true,
  raise: false,
  reporter: Doctor.Reporters.Full,
  struct_type_spec_required: true,
  umbrella: false
}
