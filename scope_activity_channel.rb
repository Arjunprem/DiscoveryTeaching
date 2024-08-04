class ScopeActivityChannel < ApplicationCable::Channel
  def subscribed
    # update_GroupResponsesCount_{id}
    stream_from params[:room]
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def init
  end
end
