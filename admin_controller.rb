class AdminController < ApplicationController
  http_basic_authenticate_with name: "TeachBackAdmin", password: "T3achB@ckT3am"

  def index
    @this_y = Date.today.year
    @all_users_count = User.count
    @all_courses_count = Course.count

    this_dt = DateTime.new(@this_y)
    this_boy = this_dt.beginning_of_year
    this_eoy = this_dt.end_of_year

    @last_y = Date.today.year - 1
    @two_y = Date.today.year - 2

    last_dt = DateTime.new(@last_y)
    last_boy = last_dt.beginning_of_year
    last_eoy = last_dt.end_of_year

    two_dt = DateTime.new(@two_y)
    two_boy = two_dt.beginning_of_year
    two_eoy = two_dt.end_of_year

    @one_week_users = User.where(created_at: 1.week.ago..DateTime.now).count
    @one_day_users = User.where(created_at: 1.day.ago..DateTime.now).count
    @two_week_users = User.where(created_at: 2.week.ago..DateTime.now).count
    @one_month_users = User.where(created_at: 1.month.ago..DateTime.now).count
    @this_year_users = User.where("created_at >= ? and created_at <= ?", this_boy, this_eoy).count
    @last_year_users = User.where("created_at >= ? and created_at <= ?", last_boy, last_eoy).count
    @two_year_users = User.where("created_at >= ? and created_at <= ?", two_boy, two_eoy).count

    @one_day_courses = Course.where(created_at: 1.day.ago..DateTime.now).count
    @one_day_meetings = Lecture.where(created_at: 1.day.ago..DateTime.now).count
    @one_day_activities = Activity.where(created_at: 1.day.ago..DateTime.now).count

    @one_week_courses = Course.where(created_at: 1.week.ago..DateTime.now).count
    @last_week_meetings = Lecture.where(created_at: 1.week.ago..DateTime.now).count
    @last_week_activities = Activity.where(created_at: 1.week.ago..DateTime.now).count

    @two_week_meetings = Lecture.where(created_at: 2.week.ago..DateTime.now).count
    @two_week_activities = Activity.where(created_at: 2.week.ago..DateTime.now).count
    @two_week_courses = Course.where(created_at: 2.week.ago..DateTime.now).count

    @one_month_meetings = Lecture.where(created_at: 1.month.ago..DateTime.now).count
    @one_month_activities = Activity.where(created_at: 1.month.ago..DateTime.now).count
    @one_month_courses = Course.where(created_at: 1.month.ago..DateTime.now).count

    @this_year_courses = Course.where("created_at >= ? and created_at <= ?", this_boy, this_eoy).count
    @last_year_courses = Course.where("created_at >= ? and created_at <= ?", last_boy, last_eoy).count
    @two_year_courses = Course.where("created_at >= ? and created_at <= ?", two_boy, two_eoy).count

		@courses = Course.all.order(created_at: :desc).first(20)
		@users = User.all.order(created_at: :desc).first(50)
    render "index"
  end

  def feedback
    @feedbacks = Feedback.all.order(created_at: :desc)
    render "feedback"
  end

  def latest
    @subscribers = Subscriber.all.order(created_at: :desc)
    render "latest"
  end

  def readAdminFeedback
    feedback = Feedback.find(params[:feedback_id])
    feedback.update(read: true) if feedback
    redirect_to adminFeedback_url
  end

  def destroyFeedback
    feedback = Feedback.find(params[:feedback_id])
    if feedback
      feedback.destroy
    end
    redirect_to adminFeedback_url
  end
end
