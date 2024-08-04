class CourseEnrollmentsController < ApplicationController
  before_action :authenticate_user!

  def create
    pin = params[:pin]
    @course = Course.find_by(instructor_pin: pin)
    course2 = Course.find_by(student_pin: pin)

    if @course
      type = 1
    elsif course2
      @course = course2
      type = 2
    else
      @course = nil
      flash.now[:alert] = "No course matching the given PIN #{pin}. Please try again."
    end
    @user = current_user
    types = ["Instructor", "Student"]
    if @course
      enrollment = CourseEnrollment.find_by(user_id: @user.id, course_id: @course.id)
      if enrollment
        # Enrollment Exists, Update
        if enrollment.enrollment_type == type
          flash[:alert] = "You're already enrolled as #{types[type - 1]}."
        else
          enrollment.update(enrollment_type: type)
          flash[:notice] = "You're re-enrolled as #{types[type - 1]}."
        end
      else
        # Create Enrollment
        CourseEnrollment.create(user: @user, course: @course, enrollment_type: type)
        flash[:notice] = "Successfully enrolled as #{types[type - 1]}."
      end
      ActionCable.server.broadcast('update_enrolledCount_' + @course.id.to_s, { enrolledCount: @course.users.count })
      @announcements = get_announcements
      @courses = @user.courses.where(past: false)
      redirect_to user_path(@user)
    else
      render "courses/new"
    end
  end

  def delete
    user = User.find_by(email: params[:email])

    if user
      enrollment = CourseEnrollment.find_by(user_id: user.id, course_id: params[:course_id])
      if enrollment
        enrollment.destroy
        flash[:notice] = "Successfully removed from the course."
      end
    end

    if params[:page] == "student"
      redirect_to user_path(user)
    elsif current_user.id == user.id
      redirect_to user_root_path
    else
      redirect_to enrolled_course_path(id: params[:course_id])
    end
  end

  private

  def get_announcements
    posts = []
    courses = @user.courses
    courses.each do |course|
      posts += course.announcements.where(created_at: (Time.now - 1.weeks)..Time.now)
    end
    posts.sort_by(&:created_at).reverse
  end
end
