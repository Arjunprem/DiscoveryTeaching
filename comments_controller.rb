class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_current_user
  before_action :set_context

  def create
    @comment = Comment.new(comment_params)
    @comment.username = @user.username
    @comment.user_id = @user.id
    @comment.post_id = @post.id
    @comment.save
    
    if not @enrollment.instructor?
      # Automatically create an active attendance for the student
      participated(@lecture,@user)
    end

    @comments = @post.comments
    web_cast_notifier('new')
    web_cast_post_notifier('update')
    redirect_to course_lecture_activity_post_path(@course, @lecture, @activity, @post)
  end

  def destroy
    @comment = @post.comments.find(params[:id])
    @comment.destroy
    web_cast_notifier('destroy')
    web_cast_post_notifier('update')
    redirect_to course_lecture_activity_post_path(@course, @lecture, @activity, @post)
  end

  def recommendComment
    @comment = @post.comments.find(params[:id])
    thumbs = @comment.thumbs.split("::").select { |t| t != "" }
    if !thumbs.include? @user.id.to_s
      @comment.update(thumbs: @comment.thumbs + @user.id.to_s + "::")
      flash.now[:notice] = 'Comment was successfully recommended.'
    else
      thumbs.delete(@user.id.to_s)
      @comment.update(thumbs: thumbs.join("::") + "::")
      flash.now[:notice] = 'Comment was successfully de-recommended.'
    end
    if not @enrollment.instructor?
      # Automatically create an active attendance for the student
      participated(@lecture,@user)
    end
    web_cast_notifier('update')
    redirect_to course_lecture_activity_post_path(@course, @lecture, @activity, @post)
  end

  private

  def comment_params
    params.require(:comment).permit(:body)
  end

  def set_context
    @course = Course.friendly.find(params[:course_id])
    @lecture = Lecture.find(params[:lecture_id])
    @activity = Activity.find(params[:activity_id])
    @post = Post.find(params[:post_id])
    @enrollment = CourseEnrollment.find_by(user_id: @user.id, course_id: @course.id)
    @page = "forum"
  end

  def web_cast_notifier(type)
    WebCastNotifier.new.broadcast(
      "comments_instructor#{@post.id}",
      type,
      ['ws/comments/comment_instructor'],
      locals: { post: @post, enrollment: @enrollment, comment: @comment, activity: @activity, lecture: @lecture, course: @course }
    )
    WebCastNotifier.new.broadcast(
      "comments_student#{@post.id}",
      type,
      ['ws/comments/comment_student'],
      locals: { post: @post, enrollment: @enrollment, comment: @comment, activity: @activity, lecture: @lecture, course: @course }
    )
  end
end
