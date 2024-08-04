class TaskChannel < ApplicationCable::Channel
  def subscribed
    # update_tasksCount_{id}
    stream_from params[:room]
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def init
  end
end
