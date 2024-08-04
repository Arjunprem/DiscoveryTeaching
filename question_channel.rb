class QuestionChannel < ApplicationCable::Channel
  def subscribed
    # update_questionsCount_{id}
    stream_from params[:room]
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def init
    ActionCable.server.broadcast "room_channel", message: data['message']
  end
end
