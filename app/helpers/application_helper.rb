module ApplicationHelper
  include Pagy::Frontend

  def pagy_url_for(pagy, page)
    params = request.query_parameters.merge(page: page)
    url_for(params)
  end

  def pagy_prev_url(pagy)
    page = pagy.prev || pagy.page
    pagy_url_for(pagy, page)
  end

  def pagy_next_url(pagy)
    page = pagy.next || pagy.page
    pagy_url_for(pagy, page)
  end

  def render_turbo_stream_flash_messages
    turbo_stream.update "flash" do
      render partial: "shared/flash"
    end
  end
end
