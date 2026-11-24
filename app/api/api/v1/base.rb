# frozen_string_literal: true

module Api
  module V1
    class Base < Grape::API
      version "v1", using: :path
      format :json
      prefix :api

      get :health do
        ActiveRecord::Base.connection.execute("SELECT 1")
        { status: "ok", db: "postgresql" }
      end

      resource :ingest do
        post :batch do
          result = ::Ingestion::BulkUpsertEvents.new.call(params.to_h.deep_symbolize_keys)
          if result.success?
            status 201
            result.value!
          else
            code, details = result.failure
            error!({ error: code, details: details }, 422)
          end
        end
      end

      resource :analytics do
        get :anomalies do
          rows = ::Queries::Analytics::WindowAnomalyQuery.call(
            tenant_id: params[:tenant_id].to_s,
            event_name: params[:event_name].to_s,
            z_threshold: (params[:z_threshold] || 2.0).to_f
          )
          { rows: rows }
        end

        get :retention do
          rows = ::Queries::Analytics::CohortRetentionQuery.call(
            tenant_id: params[:tenant_id].to_s
          )
          { cohorts: rows }
        end
      end

      resource :exports do
        get :ndjson do
          content_type "application/x-ndjson"
          env["api.format"] = :txt
          body = +""
          ::Exports::KeysetNdjsonExporter.stream(tenant_id: params[:tenant_id].to_s, batch_size: 200).each do |line|
            body << line
          end
          body
        end
      end
    end
  end
end
