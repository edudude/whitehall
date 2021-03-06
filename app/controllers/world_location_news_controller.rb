class WorldLocationNewsController < PublicFacingController
  enable_request_formats index: [:atom, :json]
  before_action :load_world_location, only: :index
  before_action :setup_a_b_test, only: :index

  def index
    recently_updated_source = @world_location.published_editions.with_translations(I18n.locale).in_reverse_chronological_order
    respond_to do |format|
      format.html do
        if render_b_variant?
          set_meta_description("What the UK government is doing in #{@world_location.name}.")
          set_slimmer_world_locations_header([@world_location])

          @recently_updated = recently_updated_source.limit(3)
          @feature_list = FeatureListPresenter.new(@world_location.feature_list_for_locale(I18n.locale), view_context).limit_to(5)
        else
          redirect_to world_location_path(@world_location)
        end
      end
      format.json do
        redirect_to api_world_location_path(@world_location, format: :json)
      end
      format.atom do
        @documents = EditionCollectionPresenter.new(recently_updated_source.limit(10), view_context)
      end
    end
  end

private

  def load_world_location
    @world_location = WorldLocation.with_translations(I18n.locale).find(params[:world_location_id])
  end

  def setup_a_b_test
    ab_test = GovukAbTesting::AbTest.new("WorldwidePublishingTaxonomy", dimension: 45)
    @requested_variant = ab_test.requested_variant(request.headers)
    @requested_variant.configure_response(response)
  end

  def render_b_variant?
    @requested_variant.variant_b? &&
      worldwide_test_helper.is_under_test?(@world_location) &&
      locale_is_english?
  end

  def worldwide_test_helper
    @_helper ||= WorldwideAbTestHelper.new
  end

  def locale_is_english?
    locale == :en
  end
end
