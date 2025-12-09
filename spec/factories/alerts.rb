FactoryBot.define do
  factory :alert do
    edge_site { nil }
    severity { 1 }
    category { "MyString" }
    title { "MyString" }
    message { "MyText" }
    metric_type { "MyString" }
    threshold_value { "9.99" }
    actual_value { "9.99" }
    status { 1 }
    triggered_at { "2025-12-08 19:13:41" }
    acknowledged_at { "2025-12-08 19:13:41" }
    resolved_at { "2025-12-08 19:13:41" }
  end
end
