require "test_helper"

module GobiertoAdmin
  module GobiertoCms
    class PagePreviewTest < ActionDispatch::IntegrationTest
      def setup
        super
        @path = admin_cms_pages_path
      end

      def admin
        @admin ||= gobierto_admin_admins(:nick)
      end

      def site
        @site ||= sites(:madrid)
      end

      def published_page
        @published_page ||= gobierto_cms_pages(:consultation_faq)
      end

      def draft_page
        @draft_page ||= site.pages.draft.first
      end

      def test_preview_published_page
        with_signed_in_admin(admin) do
          with_current_site(site) do
            visit @path
            click_link 'News'
            within "tr#page-item-#{published_page.id}" do
              preview_link = find('a', text: 'View page')

              refute preview_link[:href].include?(admin.preview_token)

              preview_link.click
            end

            assert_equal gobierto_cms_page_path(published_page.slug), current_path
            assert has_selector?('h1', text: published_page.title)
          end
        end
      end

      def test_preview_draft_page_as_admin
        with_signed_in_admin(admin) do
          with_current_site(site) do
            visit @path
            click_link 'News'

            within "tr#page-item-#{draft_page.id}" do
              preview_link = find('a', text: 'View page')

              assert preview_link[:href].include?(admin.preview_token)

              preview_link.click
            end

            assert_equal gobierto_cms_page_path(draft_page.slug), current_path
            assert has_selector?('h1', text: draft_page.title)
          end
        end
      end

      def test_preview_draft_page_if_not_admin
        with_current_site(site) do

          assert_raises ActiveRecord::RecordNotFound do
            visit gobierto_cms_page_path(draft_page.slug)
          end

          # assert_response :not_found
          refute has_selector?('h1', text: draft_page.title)
        end
      end

    end
  end
end
