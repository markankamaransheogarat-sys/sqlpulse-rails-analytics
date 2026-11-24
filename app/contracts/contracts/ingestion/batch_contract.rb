# frozen_string_literal: true

module Contracts
  module Ingestion
    class BatchContract < Dry::Validation::Contract
      EventSchema = Dry::Schema.Params do
        required(:event_id).filled(:string, max_size?: 128)
        required(:user_key).filled(:string, max_size?: 128)
        required(:event_name).filled(:string, max_size?: 64)
        optional(:amount_cents).filled(:integer, gteq?: 0)
        optional(:currency).filled(:string, size?: 3)
        optional(:properties).hash
        required(:occurred_at).filled(:time)
      end

      params do
        required(:tenant_id).filled(:string, max_size?: 64)
        required(:events).filled(:array, min_size?: 1, max_size?: 5000).each(EventSchema)
      end
    end
  end
end
