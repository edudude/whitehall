require 'equivalent-xml'

module SyncChecker
  module Checks
    UnpublishedCheck = Struct.new(:document) do
      attr_reader :response, :content_item, :unpublishing
      def call(response)
        failures = []
        @response = response

        return [] unless there_is_an_unpublishing?

        if there_is_an_item_in_the_content_store?
          @content_item = JSON.parse(response.body)
          if published_edition_has_unpublishing?
            #withdraw
            unpublishing = document.published_edition.unpublishing
            failures << check_for_withdrawn_notice(unpublishing)
            failures << check_withdrawn_at(unpublishing)
          elsif pre_publication_has_unpublishing?
            unpublishing = document.pre_publication_edition.unpublishing
            if unpublishing.unpublishing_reason_id == 1
              #in error
              if unpublishing.redirect?
                #with redirect
                failures << check_for_redirect
              else
                #without
                failures << check_explanation(unpublishing)
                failures << check_alternative_path(unpublishing)
                failures << check_for_gone
              end
            else
              #consolidated
              failures << check_for_redirect
            end
          end
        else
          failures << "item is unpublished but there is no item in the content store"
        end

        failures.compact
      end

    private

      def there_is_an_item_in_the_content_store?
        response.body != ""
      end

      def there_is_an_unpublishing?
        published_edition_has_unpublishing? || pre_publication_has_unpublishing?
      end

      def published_edition_has_unpublishing?
        document.published_edition && document.published_edition.unpublishing
      end

      def pre_publication_has_unpublishing?
        document.pre_publication_edition && document.pre_publication_edition.unpublishing
      end

      def check_for_redirect
        "should be redirect" unless content_item["schema_name"] == "redirect"
      end

      def check_for_gone
        "should be gone" unless content_item["schema_name"] == "gone"
      end

      def check_explanation(unpublishing)
        item_explanation = content_item["details"]["explanation"]
        return if unpublishing.explanation.blank? && item_explanation.blank?

        explanation = Whitehall::GovspeakRenderer.new.govspeak_to_html(unpublishing.explanation)

        if !EquivalentXml.equivalent?(explanation, item_explanation)
          "expected gone explanation: '#{explanation}' but got '#{item_explanation}'"
        end
      end

      def check_alternative_path(unpublishing)
        alternative_url = unpublishing.alternative_url
        alternative_path = URI(alternative_url.strip).path

        item_alternative_path = content_item["details"]["alternative_path"]
        if alternative_path != item_alternative_path
          "expected gone alternative_path: '#{alternative_path}' but got '#{item_alternative_path}'"
        end
      end

      def check_for_withdrawn_notice(unpublishing)
        item_withdrawn_explanation = content_item["withdrawn_notice"]["explanation"]
        return if unpublishing.explanation.blank? && item_withdrawn_explanation.blank?

        withdrawn_explanation = Whitehall::GovspeakRenderer.new.govspeak_to_html(unpublishing.explanation)

        if !EquivalentXml.equivalent?(withdrawn_explanation, item_withdrawn_explanation)
          "expected withdrawn notice: '#{withdrawn_explanation}' but got '#{item_withdrawn_explanation}'"
        end
      end

      def format_date(date)
        time = Time.zone.parse(date.to_s)
        return "" unless time
        time.utc
      end

      def check_withdrawn_at(unpublishing)
        item_withdrawn_at = format_date(content_item["withdrawn_notice"]["withdrawn_at"])
        return "expected withdrawn at but was missing" if item_withdrawn_at.blank?

        edition_withdrawn_at = format_date(unpublishing.edition.updated_at)
        if item_withdrawn_at != edition_withdrawn_at
          "expected withdrawn at '#{edition_withdrawn_at}' but got '#{item_withdrawn_at}'"
        end
      end
    end
  end
end
