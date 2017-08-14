# frozen_string_literal: true

require "test_helper"

module GobiertoAdmin
  class UpdateIssueTest < ActionDispatch::IntegrationTest
    def setup
      super
      @path = admin_issues_path
    end

    def admin
      @admin ||= gobierto_admin_admins(:nick)
    end

    def site
      @site ||= sites(:madrid)
    end

    def participation_issue
      @participation_issue ||= gobierto_admin_issues(:culture)
    end

    def test_update_issue
      with_javascript do
        with_signed_in_admin(admin) do
          with_current_site(site) do
            visit @path

            click_link "Culture"

            within "form.edit_issue" do
              fill_in "issue_name_translations_en", with: "Theme Culture updated"
              fill_in "issue_description_translations_en", with: "Description Culture updated"
              fill_in "issue_slug_translations_en", with: "theme-culture-updated"

              click_button "Update"
            end

            assert has_message?("Theme was successfully updated.")
          end
        end
      end
    end
  end
end
