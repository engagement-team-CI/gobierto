# frozen_string_literal: true

module GobiertoDashboards
  module Api
    module V1
      class DashboardsController < BaseController
        include ::GobiertoCommon::SecuredWithAdminToken

        skip_before_action :set_admin_with_token, only: [:index, :show, :data]

        # GET /api/v1/dashboards
        # GET /api/v1/dashboards.json
        def index
          render(
            json: filtered_relation,
            adapter: :json_api
          )
        end

        # GET /api/v1/dashboards/1
        # GET /api/v1/dashboards/1.json
        def show
          find_resource

          render(
            json: @resource,
            adapter: :json_api
          )
        end

        # GET /api/v1/dashboards/1/data
        # GET /api/v1/dashboards/1/data.json
        def data
          find_resource

          render(
            json: @resource,
            serializer: ::GobiertoDashboards::DashboardDataSerializer,
            adapter: :json_api
          )
        end

        # GET /api/v1/dashboards/new
        # GET /api/v1/dashboards/new.json
        def new
          render(
            json: base_relation.new,
            adapter: :json_api
          )
        end

        # POST /api/v1/dashboards
        # POST /api/v1/dashboards.json
        def create
          @form = form_class.new(resource_params.merge(site_id: current_site.id, admin_id: current_admin.id))

          if @form.save
            render(
              json: @form.resource,
              status: :created,
              adapter: :json
            )
          else
            api_errors_render(@form, adapter: :json_api)
          end
        end

        # PATCH/PUT /api/v1/dashboards/1
        # PATCH/PUT /api/v1/dashboards/1.json
        def update
          find_resource

          @form = form_class.new(resource_params.merge(site_id: current_site.id, admin_id: current_admin.id, id: @resource.id))

          if @form.save
            render(
              json: @form.resource,
              adapter: :json
            )
          else
            api_errors_render(@form, adapter: :json_api)
          end
        end

        # DELETE /api/v1/dashboards/1
        # DELETE /api/v1/dashboards/1.json
        def destroy
          find_resource

          @resource.destroy

          head :no_content
        end

        private

        def find_resource
          @resource = base_relation.find(params[:id])
        end

        def context_resource
          @context_resource ||= GobiertoCommon::ContextService.new(params[:context])
        end

        def base_relation
          current_site.dashboards.active
        end

        def filtered_relation
          params[:context].present? ? base_relation.where(context: context_resource.context) : base_relation
        end

        def form_class
          DashboardForm
        end

        def resource_params
          ActiveModelSerializers::Deserialization.jsonapi_parse(params, only: [:title_translations, :title, :context, :widgets_configuration, :visibility_level])
        end
      end
    end
  end
end
