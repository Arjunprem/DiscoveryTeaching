class ActivitiesController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => :rateActivity
  skip_before_action :verify_authenticity_token, :only => :saveNotes
  before_action :set_activity, except: %i[new create index]
  before_action :set_class
  before_action :set_user
  before_action :set_enrollment, except: [:refreshTimeline]
  before_action :check_access, only: %i[edit new index destroy hideActivity activateActivity
                                        createGroups lectureGroups update]

  def new
    @activity = Activity.new
  end

  def edit
    @page = ''
    @page_libs = [:checkbox]
  end

  def index
    redirect_to course_lecture_url(@course, @lecture)
  end

  def activateActivity
    @activities = @lecture.activities
    @activities.where(active: true).update_all(active: false)
    @activity.update(active: true)
    web_cast_notifier('update')
    render 'show_instructor'
  end

  def hideQuestions
    @page = 'iResponder'
    if !@activity.hide_questions
      @questions = []
      @activity.update(hide_questions: true)
    else
      @questions = @activity.questions.order(created_at: :asc).select(Question::INDEX_COLUMNS)
      @activity.update(hide_questions: false)
    end

    if @enrollment.instructor?
      render 'questions/index_instructor'
    else
      render 'questions/index_student'
    end
  end

  def hideActivity
    if @activity.hidden
      @activity.update(hidden: false)
      web_cast_notifier('new')
    else
      @activity.update(hidden: true)
      web_cast_notifier('destroy')
    end
    redirect_to course_lecture_url(@course, @lecture)
  end

  def hideTasks
    @page = 'groups'
    @tab = 'taskList'
    @groups = @lecture.groups
    if !@activity.hide_tasks
      @tasks = []
      @activity.update(hide_tasks: true)
    else
      @tasks = @activity.tasks
      @activity.update(hide_tasks: false)
    end

    if @enrollment.instructor?
      render 'tasks/index_instructor'
    else
      render 'tasks/index_student'
    end
  end

  def createGroups
    @tab = 'groups'
    @tasks = @activity.tasks
    ActiveRecord::Base.transaction do
      lock = Lock.find(@lecture.lock_id)
      Lock.uncached do
        lock.with_lock(lock = true) do
          @lecture.groups.destroy_all
          attendees = @lecture.attendances.pluck(:user_id)
          attendees.each_slice(3) { |ids|
            @lecture.groups.create(student_ids: ids.join(':'), title: 'Group #' + (@lecture.groups.size + 1).to_s)
          }
        end
      end
    end
    @groups = @lecture.groups.order(created_at: :asc)
    @page = 'tasks'
    render 'tasks/index_instructor'
  end

  def activityStats
    @page = 'stats'
    activity_posts = @activity.posts
    post_ids = activity_posts.pluck(:id)
    activity_ids = @activity.id
    if @enrollment.instructor?
      @students = @course.students

      case params[:tab]
        when 'iResponder' then tabIresponder()
        when 'forum' then tabForum(post_ids, activity_posts)
        when 'attendance' then tabAttendance()
        when 'feedback' then tabFeedback()
        else tabGroup(activity_ids)
      end
      @page_libs = [:tablesorter]
      render 'stats_instructor'

    else
      @page_libs = [:highcharts]
      @sentiments = @lecture.sentiments
      last = SentimentRecord.where(user_id: @user.id, activity_id: @activity.id).last
      @active_sentiment = Sentiment.find(last.sentiment_id) if last
      activity_ids = @activity.id
      questions = @activity.questions

      @ungraded_ids = questions.not_graded.pluck(:id)
      @graded_ids = questions.graded.pluck(:id)
      @graded_answers = Answer.where(question_id: @graded_ids, user_id: @user.id)
      @ungraded_answers = Answer.where(question_id: @ungraded_ids, user_id: @user.id)

      dataGroupStats(activity_ids)

      @attendance = Attendance.find_by(lecture_id: @lecture.id, user_id: @user.id)
      @posts = activity_posts.where(user_id: @user.id)
      @comment_count = Comment.where(post_id: post_ids, user_id: @user.id).count
      @counts = @activity.sentiment_records.where(user_id: @user.id).group(:sentiment_id).count
      @sentiments1 = @lecture.sentiments.pluck(:id, :title)
      @colors = @lecture.sentiments.pluck(:color)
      @messages = SentimentManager.getUserMessages(@activity, @user)

      render 'stats_student'
    end
  end

  def lectureGroups
    @tab = 'groups'
    @tasks = @activity.tasks

    @groups = @lecture.groups.order(created_at: :asc)
    @page = 'tasks'
    render 'tasks/index_instructor'
  end

  def myGroup
    @tab = 'mygroup'
    @page = 'tasks'
    @mygroup = nil
    @lecture.groups.each do |group|
      ids = group.last_ids
      if ids.include? @user.id.to_s
        @mygroup = group
        break
      end
    end
    @sentiments = @lecture.sentiments
    last = SentimentRecord.where(user_id: @user.id, activity_id: @activity.id).last
    @active_sentiment = Sentiment.find(last.sentiment_id) if last
    @tasks = @activity.hide_tasks ? [] : @activity.tasks.where(hidden: false).order(created_at: :desc)
    render 'tasks/index_student'
  end

  def show
    if @enrollment.instructor?
      @page_libs = %i[highcharts tablesorter checkbox tagsinput]
      render 'show_instructor'
    else
      @page_libs = %i[highcharts checkbox]
      # Automatically group a student when first visiting an activity page
      if @lecture.activities.any? { |a| a.tasks.any? } or @lecture.groups.any?
        group_students(@lecture, @user)
      end

      # Automatically create a present attendance for the student
      showed_up(@lecture,@user)

      @sentiments = @lecture.sentiments
      last = SentimentRecord.where(user_id: @user.id, activity_id: @activity.id).last
      @active_sentiment = Sentiment.find_by(id: last&.sentiment_id)

      rating = ActivityRating.find_by(user_id: @user.id, activity_id: @activity.id)
      @myrating = rating&.rating

      @notes = Note.find_by(user_id: @user.id, activity_id: @activity.id)

      render 'show_student'
    end
  end

  def shareNotes
  
    @page_libs = %i[highcharts checkbox]
    # Automatically group a student when first visiting an activity page
    if @lecture.activities.any? { |a| a.tasks.any? } or @lecture.groups.any?
      group_students(@lecture, @user)
    end

    # Automatically create a present attendance for the student
    showed_up(@lecture,@user)

    @sentiments = @lecture.sentiments
    last = SentimentRecord.where(user_id: @user.id, activity_id: @activity.id).last
    @active_sentiment = Sentiment.find_by(id: last&.sentiment_id)

    rating = ActivityRating.find_by(user_id: @user.id, activity_id: @activity.id)
    @myrating = rating&.rating

    @notes = Note.find_by(user_id: @user.id, activity_id: @activity.id)
    @notes.update(shared: true)
    render 'show_student'

  end

  def sharedNotes
    @page = 'shared_notes'
    @notes = Note.where(activity_id: @activity.id, shared: true)
    @notesCount = @notes.count

    if @enrollment.instructor?
      @page_libs = %i[highcharts tablesorter checkbox tagsinput]
      render 'notes_instructor'
    else
      @sentiments = @lecture.sentiments
      last = SentimentRecord.where(user_id: @user.id, activity_id: @activity.id).last
      @active_sentiment = Sentiment.find_by(id: last&.sentiment_id)

      rating = ActivityRating.find_by(user_id: @user.id, activity_id: @activity.id)
      @myrating = rating&.rating
      render 'notes_student'
    end
  end

  def editNotes
    @page_libs = [:checkbox]
    @notes = Note.find_by(user_id: @user.id, activity_id: @activity.id)
    @sentiments = @lecture.sentiments
    last = SentimentRecord.where(user_id: @user.id, activity_id: @activity.id).last
    @active_sentiment = Sentiment.find(last.sentiment_id) if last
    render 'edit_notes'
  end

  def saveNotes
    @notes = Note.find_by(user_id: @user.id, activity_id: @activity.id)
    if @notes
      @notes.update(body: params[:body], shared: params[:shared])
    else
      @notes = Note.create(user_id: @user.id, activity_id: @activity.id, body: params[:body], shared: params[:shared])
    end

    # Automatically create an active attendance for the student
    showed_up(@lecture,@user)

    @sentiments = @lecture.sentiments
    last = SentimentRecord.where(user_id: @user.id, activity_id: @activity.id).last
    @active_sentiment = Sentiment.find(last.sentiment_id) if last
    render 'show_student'
  end

  def rateActivity
    rating = ActivityRating.find_by(user_id: @user.id, activity_id: @activity.id)
    if rating
      rating.update(rating: activity_params[:rating])
      @myrating = rating.rating
    else
      ActivityRating.create(user_id: @user.id, activity_id: @activity.id, rating: activity_params[:rating])
      @myrating = activity_params[:rating].to_i
    end
    avrg = @activity.activity_ratings.average('rating')
    @activity.update(rating: avrg)
    web_cast_notifier('update')
    @sentiments = @lecture.sentiments
    last = SentimentRecord.where(user_id: @user.id, activity_id: @activity.id).last
    @active_sentiment = Sentiment.find(last.sentiment_id) if last

    # Automatically create a showed-up attendance for the student
    showed_up(@lecture,@user)
    @notes = Note.find_by(user_id: @user.id, activity_id: @activity.id)

    render 'show_student'
  end

  def create
    @activity = Activity.new(activity_params)
    @activity.lecture_id = @lecture.id
    @page = ''
    respond_to do |format|
      if @activity.save
        if @activity.active
          @activities = @lecture.activities
          activities = @activities.where.not(active: false, id: @activity.id)
          activities.update_all(active: false)
        end
        web_cast_notifier('new')
        format.html { redirect_to course_lecture_url(@course, @lecture), notice: 'Activity was successfully created.' }
        format.json { render action: 'lecture#show', status: :created, location: @lecture }
      else
        @page_libs = [:checkbox]
        format.html { render action: 'new' }
        format.json { render json: @activity.errors, status: :unprocessable_entity }
      end
    end
  end

  def feedback
    @page = 'feedback'
    @sentiments = @lecture.sentiments
    if @enrollment.instructor?
      @lectureActive = SentimentManager.lectureActive? @lecture
      @counts = @activity.latest_sentiments.group(:sentiment_id).count
      @sentiments = @lecture.sentiments.pluck(:id, :title, :color, :description)
      @messages = SentimentManager.getLatestMessages(@activity)
      @points, @history_counts, @timeline_messages = SentimentManager.getSentHistory(@activity)
      @page_libs = [:highcharts]
      render 'feedback_instructor'
    else
      last = SentimentRecord.where(user_id: @user.id, activity_id: @activity.id).last
      @active_sentiment = last.sentiment_id if last
      render 'feedback_student'
    end
  end

  def refreshTimeline
    # SentimentManager.updateTimeline(@activity)
    redirect_back(fallback_location: adminFeedback_path)
  end

  def record_sentiment
    @sentiments = @lecture.sentiments
    if @sentiments.pluck(:id).include? params[:sentiment_id].to_i
      SentimentManager.recordSentiment(@user.id, @activity.id, params[:sentiment_id].to_i, params[:message])
      @active_sentiment = Sentiment.find(params[:sentiment_id].to_i)
    else
      last = SentimentRecord.where(user_id: @user.id, activity_id: @activity.id).last
      @active_sentiment = Sentiment.find(last.sentiment_id) if last
    end
    @page = 'feedback'

    # Automatically create an active attendance for the student
    participated(@lecture,@user)

    respond_to do |format|
      format.js
    end
  end

  def update
    respond_to do |format|
      if @activity.update(activity_params)
        if @activity.active
          @activities = @lecture.activities
          @activities.where.not(active: false, id: @activity.id).update_all(active: false)
        end
        web_cast_notifier('update')
        format.html { redirect_to edit_course_lecture_activity_url, notice: 'Activity was successfully updated.'}
        format.json { head :no_content }
      else
        @page = ''
        format.html { render action: 'edit' }
        format.json { render json: @activity.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @activity.destroy
    web_cast_notifier('destroy')
    respond_to do |format|
      format.html { redirect_to course_lecture_url(@course, @lecture), notice: 'Activity was successfully deleted.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_activity
    @activity = Activity.find(params[:id])
    unless @activity
      redirect_to course_lecture_url(@course, @lecture), alert: 'No Activity with id:#{params[:id]}.'
    end
  end

  # Never trust parameters from the scary Internet, only allow the white list through.
  def activity_params
    params.require(:activity).permit(:groups, :title, :hide_questions, :body, :shared, :goals, :lecture_id, :iResponder, :feedback, :forum, :rating, :active)
  end

  # Sets current lecture
  def set_class
    @lecture = Lecture.find(params[:lecture_id])
    @course = Course.friendly.find(params[:course_id])
    @page = 'activity'
  end

  def tabIresponder()
    check_access()
    @tab = 'iResponder'
    @questions = @activity.questions;
    graded_ids = @questions.where(graded: true, hidden: false).pluck(:id);
    visible_ids = @questions.where(hidden: false).pluck(:id);
    @data = {};
    @students.each do |student|
      answers = Answer.where(question_id: graded_ids, user_id: student.id)
      visible_answers = Answer.where(question_id: visible_ids, user_id: student.id)

      @data[student.id] = {
        perCorrect: percentage((answers.correct_grades), answers),
        answered: "#{visible_answers.size}/#{visible_ids.size}",
        points: answers.pluck(:points).select { |point| point != nil }.inject(:+) || 0.0
      }
    end
    @questions.each do |question|
      answers = Answer.where(question_id: question.id)
      answers.each do |answer|
        if @data[answer.user_id]
          @data[answer.user_id][question.id] = [answer.grading, answer.points]
        end
      end
    end
  end

  def tabForum(post_ids, activity_posts)
    @tab = 'forum'
    @data = {}
    @students.each do |student|
      posts = activity_posts.where(user_id: student.id)
      @data[student.id] = {
          postCount: posts.count,
          questionCount: posts.questions.count,
          noteCount: posts.notes.count,
          privateCount: posts.private_posts.count,
          commentCount: Comment.where(post_id: post_ids, user_id: student.id).count
      }
    end
  end

  def tabAttendance()
    @tab = 'attendance'
    @attendances = @lecture.attendances
  end

  def tabFeedback()
    @tab = 'feedback'
    @sentiments = @lecture.sentiments
    @data = {}
    @students.each do |student|
      records = @activity.sentiment_records.where(user_id: student.id)
      @data[student.id] = {
        counts: records.group(:sentiment_id).count,
        feedCount: records.count,
        messages: SentimentManager.getUserMessages2(@activity, student.id)
      }
    end
  end

  def web_cast_notifier(type)
    WebCastNotifier.new.broadcast(
      "activity_instructor#{@lecture.id}",
      type,
      ['ws/activities/activity_instructor'],
      locals: { activity: @activity, lecture: @lecture, course: @course }
    )

    WebCastNotifier.new.broadcast(
      "activity_student#{@lecture.id}",
      type,
      ['ws/activities/activity_student'],
      locals: { activity: @activity, lecture: @lecture, course: @course }
    )
  end
end
