# frozen_string_literal: true

module GobiertoParticipation
  class ContributionForm
    include ActiveModel::Model

    attr_accessor(
      :id,
      :user_id,
      :contribution_container_id,
      :title,
      :body
    )

    delegate :persisted?, to: :contribution

    def save
      save_contribution if valid?
    end

    def contribution
      @contribution ||= contribution_class.find_by(id: id).presence || build_contribution
    end

    private

    def build_contribution
      contribution_class.new
    end

    def contribution_class
      ::GobiertoParticipation::Contribution
    end

    def save_contribution
      @contribution = contribution.tap do |contribution_attributes|
        contribution_attributes.user_id = user_id
        contribution_attributes.contribution_container_id = contribution_container_id
        contribution_attributes.title = title
        contribution_attributes.body = body
      end

      if @contribution.valid?
        @contribution.save

        @contribution
      else
        promote_errors(@contribution.errors)

        false
      end
    end

    protected

    def promote_errors(errors_hash)
      errors_hash.each do |attribute, message|
        errors.add(attribute, message)
      end
    end
  end
end
