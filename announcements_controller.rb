class AnnouncementsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user
  before_action :set_course
  before_action :check_access, only: [:create, :destroy]

  def create
    @announcement = Announcement.new(announcement_params)
    @announcement.course_id = @course.id
    @announcement.user_name = @user.first_name + " " + @user.last_name
    @enrollment = CourseEnrollment.find_by(user_id: @user.id, course_id: @course.id)

    respond_to do |format|
      if @announcement.save
        web_cast_notifier('new')
        format.html { redirect_to course_url(@course), notice: 'Announcement was successfully created.' }
        format.json { render action: 'course/show', status: :created, location: @course }
      else
        format.html { redirect_to course_url(@course), alert: 'Announcement could not be created.' }
        format.json { render json: @announcement.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @announcement = Announcement.find(params[:id])
    @announcement.destroy
    web_cast_notifier('destroy')
    flash[:notice] = 'Announcement was successfully deleted.'
    redirect_to course_url(@course)
  end

  private

  def web_cast_notifier(type)
    WebCastNotifier.new.broadcast(
      "announcement_instructor#{@course.id}",
      type,
      ['ws/announcements/announcement_instructor'],
      locals: { announcement: @announcement, enrollment: @enrollment, course: @course }
    )

    WebCastNotifier.new.broadcast(
      "announcement_student#{@course.id}",
      type,
      ['ws/announcements/announcement_student'],
      locals: { announcement: @announcement, enrollment: @enrollment, course: @course }
    )
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def announcement_params
    params.require(:announcement).permit(:body, :important, :title, :global)
  end
end
