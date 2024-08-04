# ToDo where used in the project ?
class AttendancesController < ApplicationController
  before_action :set_context
  before_action :set_current_user

  def toggleAttendance
    @attendance = Attendance.find(params[:id])
    if @attendance
      @attendance.update(present: params[:present])
    else
      Attendance.create(user_id: params[:present], lecture_id: @lecture.id, present: params[:present])
    end
    @students = @course.students
    @attendances = @lecture.attendances
    @tab = "attendance"
    render "stats_instructor"
  end

  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def attendance_params
    params.require(:attendance).permit(:present)
  end

  # Sets current lecture
  def set_context
    @lecture = Lecture.find(params[:lecture_id])
    @course = Course.friendly.find(params[:course_id])
  end
end
