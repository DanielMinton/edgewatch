FactoryBot.define do
  factory :metric do
    edge_site { nil }
    metric_type { "MyString" }
    value { "9.99" }
    unit { "MyString" }
    node_name { "MyString" }
    pod_name { "MyString" }
    namespace { "MyString" }
    labels { "" }
    recorded_at { "2025-12-08 19:13:29" }
  end
end
