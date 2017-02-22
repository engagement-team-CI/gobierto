module GobiertoAdmin
  module GobiertoBudgetConsultations
    module Consultations
      class ConsultationResponsesController < Consultations::BaseController
        def index
          respond_to do |format|
            format.html do
              @consultation_responses = @consultation.consultation_responses.sorted
            end
            format.js
          end
        end

        def new
          @consultation_items = find_consultation_items
          @consultation_response_form = ConsultationResponseForm.new(consultation_id: @consultation.id, document_number_digest: params[:document_number_digest])
        end

        def create
          @consultation_response_form = ConsultationResponseForm.new(consultation_response_params.merge(consultation_id: @consultation.id))

          if @consultation_response_form.save
            redirect_to(edit_admin_budget_consultation_path(@consultation), notice: t(".success"))
          else
            flash[:error] = t(".error")
            @consultation_items = find_consultation_items
            render :new
          end
        end

        def show
          respond_to do |format|
            format.html do
              @consultation_response = find_consultation_response
            end
            format.js do
              if @census_item = find_census_item
                @consultation_response = find_consultation_response_by_document_number
              end
            end
          end
        end

        def destroy
          @consultation_response = find_consultation_response
          @consultation_response.destroy

          respond_to do |format|
            format.html do
              redirect_to edit_admin_budget_consultation_path(@consultation)
            end
            format.js
          end
        end

        private

        def find_consultation_items
          @consultation.consultation_items.sorted
        end

        def consultation_response_params
          params.require(:consultation_response).permit!
        end

        def find_consultation_response
          @consultation.consultation_responses.find(params[:id])
        end

        def find_census_item
          site = @consultation.site
          document_number_digest = ::SecretAttribute.digest(params[:id])
          CensusItem.find_by(document_number_digest: document_number_digest, site_id: site.id)
        end

        def find_consultation_response_by_document_number
          @consultation.consultation_responses.find_by_document_number(params[:id])
        end
      end
    end
  end
end
