# frozen_string_literal: true

module GobiertoAdmin
  class Permission::GobiertoParticipation < GroupPermission
    default_scope -> { where(namespace: "site_module", resource_type: "gobierto_participation") }
  end
end
