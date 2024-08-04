# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session
  before_action :configure_permitted_parameters, if: :devise_controller?

  # before_action :store_user_location!, if: :storable_location?
  # The callback which stores the current location must be added before you authenticate the user
  # as `authenticate_user!` (or whatever your resource is) will halt the filter chain and redirect
  # before the location can be stored.

  # def after_sign_in_path_for(resource)
  #   user_path(current_user)
  # end

  # Route to user page on sign-in
  def after_sign_in_path_for(resource_or_scope)
    stored_location_for(resource_or_scope) || user_path(current_user)
  end

  def after_updated_account_path_for(resource)
  	edit_user_registration_path
  end

  def tabGroup(activity_ids)
    @tab = 'group'
    @tasks = Task.where(activity_id:activity_ids)
    @task_ids = @tasks.pluck(:id)
    graded_ids = @tasks.where(graded:true).pluck(:id)
    ungraded_ids = @tasks.where(graded:false).pluck(:id)
    @students_data = {}
    @students.each do |student|
      ind_graded = Response.where(task_id:graded_ids,user_id:student.id,individual:true)
      ind_ungraded = Response.where(task_id:ungraded_ids,user_id:student.id,individual:true)

      graded = Response.where(task_id:graded_ids,in_group:true)
      ungraded = Response.where(task_id:ungraded_ids,in_group:true)
      group_graded = []
      group_ungraded = []
      graded.each do |res|
        votes = res.votes.split('::').select{|t| (t!='') && !t.nil?}
        group_graded << res.id if votes.include? student.id.to_s
      end
      ungraded.each do |res|
        votes = res.votes.split('::').select{|t| (t!='') && !t.nil?}
        group_ungraded << res.id if votes.include? student.id.to_s
      end
      group_graded = graded.where(id:group_graded)
      group_ungraded = ungraded.where(id:group_ungraded)

      ind_correct = ind_graded.where(grading:2)
      group_correct = group_graded.where(grading:2)

      @students_data[student.id] = {
        ind_ungraded: ind_ungraded.count.to_s+'/'+ungraded_ids.size.to_s,
        group_ungraded: group_ungraded.count.to_s+'/'+ungraded_ids.size.to_s,
        ind_points: ind_graded.pluck(:points).reject(&:nil?).inject(:+) || 0.0,
        group_points: group_graded.pluck(:points).reject(&:nil?).inject(:+) || 0.0,
        ind_percent_answered: percentage(ind_graded, graded_ids),
        group_percent_answered: percentage(group_graded, graded_ids),
        ind_percent_correct: percentage(ind_correct, ind_graded),
        group_percent_correct: percentage(group_correct, group_graded)
      }
    end
  end

  def dataGroupStats(activity_ids)

    tasks = Task.where(activity_id:activity_ids)
    graded_ids = tasks.where(graded:true).pluck(:id)
    ungraded_ids = tasks.where(graded:false).pluck(:id)
    ind_graded = Response.where(task_id:graded_ids,user_id:@user.id,individual:true)
    ind_ungraded = Response.where(task_id:ungraded_ids,user_id:@user.id,individual:true)

    graded = Response.where(task_id:graded_ids,user_id:@user.id,in_group:true)
    ungraded = Response.where(task_id:ungraded_ids,user_id:@user.id,in_group:true)
    group_graded = []
    group_ungraded = []
    graded.each do |res|
      votes = res.votes.split('::').select{|t| (t!='') && !t.nil?}
      group_graded << res.id if votes.include? @user.id.to_s
    end
    ungraded.each do |res|
      votes = res.votes.split('::').select{|t| (t!='') && !t.nil?}
      group_ungraded << res.id if votes.include? @user.id.to_s
    end
    group_graded = graded.where(id:group_graded)
    group_ungraded = ungraded.where(id:group_ungraded)
    ind_correct = ind_graded.where(grading:2)
    group_correct = group_graded.where(grading:2)
    @group_data = {
      ind_ungraded: ind_ungraded.count.to_s+'/'+ungraded_ids.size.to_s,
      group_ungraded: group_ungraded.count.to_s+'/'+ungraded_ids.size.to_s,
      ind_graded: ind_graded.count.to_s+'/'+graded_ids.size.to_s,
      group_graded: group_graded.count.to_s+'/'+graded_ids.size.to_s,
      ind_points: ind_graded.pluck(:points).reject(&:nil?).inject(:+) || 0.0,
      group_points: group_graded.pluck(:points).reject(&:nil?).inject(:+) || 0.0,
      ind_percent_answered: percentage(ind_graded, graded_ids),
      group_percent_answered: percentage(group_graded, graded_ids),
      ind_percent_correct: percentage(ind_correct, ind_graded),
      ind_correct: percentage(ind_correct, ind_graded),
      group_percent_correct: percentage(group_correct, group_graded),
      group_correct: percentage(group_correct, group_graded)
    }
  end

  def participated(lecture,user=@user)
    # Automatically create an active attendance for the student
    if SentimentManager.lectureActive? lecture
      attendance = Attendance.find_by(user_id: user.id, lecture_id: lecture.id)
      if attendance && (attendance.status != 1)
        attendance.update(status: 1)
      elsif !attendance
        Attendance.create(user_id: user.id, lecture_id: lecture.id, status: 1)
      end
    end
  end

  def showed_up(lecture,user=@user)
    # Automatically create an active attendance for the student
    if SentimentManager.lectureActive? lecture
      attendance = Attendance.find_by(user_id: user.id, lecture_id: lecture.id)
      unless attendance
        Attendance.create(user_id: user.id, lecture_id: lecture.id, status: 0)
      end
    end
  end

  def percentage(group, all)
    return 0 unless group.size.positive?

    (group.size * 100.0 / all.size).to_f.round(1)
  end

  # Sets user
  def set_user
    if current_user&.id
      @user = User.friendly.find(current_user.id)
    else
      redirect_to new_user_registration_path, errors: 'You need to sign in or sign up before continuing.'
    end
  end

  def set_current_user
    if current_user&.id
      @user = User.friendly.find(current_user.id)
    else
      redirect_to new_user_registration_path, errors: 'You need to sign in or sign up before continuing.'
    end
  end

  # Sets current course
  def set_course
    @course = Course.friendly.find(params[:course_id])
  end

  # Sets the course enrollment for the current user and course
  def set_enrollment
    set_course
    @enrollment = CourseEnrollment.where(user_id: @user.id, course_id: @course.id).select(:enrollment_type).first
    unless @enrollment&.enrollment_type
      render file: 'public/422.html', status: :not_found, layout: false
    end
  end

  # Check access
  def check_access
    set_enrollment
    unless @enrollment.instructor?
      render file: 'public/422.html', status: :not_found, layout: false
    end
  end

  def group_students(lecture,user)
    ActiveRecord::Base.transaction do
      lock = Lock.find(lecture.lock_id)
      Lock.uncached do
        lock.with_lock do
          groups = lecture.groups.order(:id)
          student_ids = groups.pluck(:student_ids).flat_map{|ids| ids.split(':')}
          student_ids = student_ids.select{|id| id!='' && !id.nil?}
          unless student_ids.include? user.id.to_s
            if !groups.empty?
              last_group = groups.last
              last_ids = []
              last_ids = last_group.last_ids if last_group
              if last_group && (last_ids.size < 3) # Add this to lecture attributes
                last_ids << user.id.to_s
                last_group.update(student_ids:last_ids.join(':'))
              else
                group = lecture.groups.create(student_ids:user.id.to_s,title:'Group #'+(groups.size+1).to_s)
              end
            else
              group = lecture.groups.create(student_ids:user.id.to_s,title:'Group #1')
            end
          end
        end
      end
    end
  end

  def web_cast_post_notifier(type)
    WebCastNotifier.new.broadcast(
      "posts_all#{@activity.id}",
      type,
      ['ws/posts/post'],
      locals: { post: @post, activity: @activity, lecture: @lecture, course: @course }
    )
  end

  private

  # Its important that the location is NOT stored if:
  # - The request method is not GET (non idempotent)
  # - The request is handled by a Devise controller such as Devise::SessionsController as that could cause an
  #    infinite redirect loop.
  # - The request is an Ajax request as this can lead to very unexpected behaviour.
  def storable_location?
    request.get? && is_navigational_format? && !devise_controller? && !request.xhr?
  end

  def store_user_location!
    # :user is the scope we are authenticating
    store_location_for(:user, request.fullpath)
  end

  protected

  # Allow additional parameters
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:account_update, keys: %i[first_name last_name username image_url avatar])
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[first_name last_name username email username image_url avatar])
    devise_parameter_sanitizer.permit(:sign_in, keys: [:email])
  end
end
