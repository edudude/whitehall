class PublishingApiGoneWorker < PublishingApiWorker
  def perform(base_path)
    gone_item = PublishingApiPresenters::Gone.new(base_path)
    send_item(base_path, gone_item.as_json)
  end
end
