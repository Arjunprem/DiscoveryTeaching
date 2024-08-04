class CoursesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user
  before_action :set_enrollment, only: [:courseNotes, :update_course_sentiments, :courseStats, :consent_stats, :showPins, :enrolled, :show, :edit, :update, :destroy]
  before_action :set_course, only: [:courseNotes, :update_course_sentiments, :courseStats, :consent_stats, :showPins, :enrolled, :show, :edit, :update, :destroy]
  before_action :check_access, only: [:update_course_sentiments, :showPins, :edit, :update, :destroy]

  def index
    redirect_to user_root_path
  end

  def edit
    @studentsCount = @course.students.count
    @announcements = @course.announcements.where(created_at: (Time.now - 1.weeks)..Time.now).reverse
  end

  # TODO  when it is called?
  def update_course_sentiments
    # Create course sentiments for all new lectures
    @course.course_sentiments.each do |cs|
      cs.destroy
    end
    sents = []
    sents.push Sentiment.find_or_create_by(title: params[:title1], description: params[:desc1], color: params[:color1])
    sents.push Sentiment.find_or_create_by(title: params[:title2], description: params[:desc2], color: params[:color2])
    sents.push Sentiment.find_or_create_by(title: params[:title3], description: params[:desc3], color: params[:color3])

    sents.each do |sent|
      if sent.valid?
        @course.course_sentiments.create(sentiment_id: sent.id)
      end
    end
    @course.update(group_size: params[:group_size].to_i)
    redirect_to edit_course_url(@course), notice: 'Sentiments were successfully updated for all new lectures'
  end

  # GET courses/:id
  def show
    @page_libs = [:tablesorter]
    @studentsCount = @course.students.count
    @announcements = @course.announcements.where(global: false, created_at: (Time.now - 1.weeks)..Time.now).reverse
    @lectures = @course.lectures.order('created_at DESC').select(:id, :title, :date, :info, :hidden, :start_time, :end_time)
    if @enrollment.instructor?
      render 'show_instructor'
    else
      render 'show_student'
    end
  end

  def courseNotes
    @enrollment = CourseEnrollment.where(user_id: @user.id, course_id: @course.id).select(:enrollment_type).first
    @studentsCount = @course.students.count
    @lectures = @course.lectures.select(:id, :title)
    lecture_ids = @lectures.pluck(:id)
    @activities = Activity.where(lecture_id: lecture_ids).select(:id, :title)
    activity_ids = @activities.pluck(:id)
    @notes = Note.where(user_id: @user.id, activity_id: activity_ids)
    render 'courseNotes'
  end

  def showPins
    @studentsCount = @course.students.count
    @lectures = @course.lectures.order('created_at DESC').select(:id, :title, :date, :info, :hidden, :start_time, :end_time)
    @announcements = @course.announcements.where(created_at: (Time.now - 1.weeks)..Time.now).reverse
    flash.now[:notice] = 'Enrollment PINS: Instructors: ' + @course.instructor_pin.to_s + ', Students: ' + @course.student_pin.to_s
    render 'show_instructor'
  end

  def consent_stats
    @agreed =  User.agreed_users(@course.id)
    @disagreed = User.disagreed_users(@course.id)
  end

  # GET courses/new
  def new
    @course = Course.new
  end

  def courseStats
    @studentsCount = @course.students.count
    if @enrollment.instructor?
      @start_date = @course.start_date
      @end_date = @course.end_date

      if params[:start_date] && params[:start_date] != ''
        @start_date = Date.parse(params[:start_date])
      end
      if params[:end_date] && params[:end_date] != ''
        @end_date = Date.parse(params[:end_date])
      end

      lecture_ids = @course.lectures.pluck(:id)
      activities = Activity.where(lecture_id: lecture_ids)
      activity_ids = activities.pluck(:id)

      @students = @course.students
      @page_libs = [:highcharts]
      case params[:tab]
      when 'iResponder' then tabIresponder(activity_ids)
      when 'at_risk' then tabAtRisk(activity_ids)
      when 'forum' then tabForum(activity_ids)
      when 'attendance' then tabAttendance(lecture_ids)
      when 'feedback' then tabFeedback(activity_ids)
      else tabGroup(activity_ids)
      end
      render 'stats_instructor'

    else
      lecture_ids = @course.lectures.pluck(:id)
      activities = Activity.where(lecture_id: lecture_ids)
      activity_ids = activities.pluck(:id)
      @lectures_count = lecture_ids.size
      @attendances = Attendance.where(lecture_id: lecture_ids, user_id: @user.id).group(:status).count
      dataGroupStats(activity_ids)

      lecture_posts = Post.where(activity_id: activity_ids)
      post_ids = lecture_posts.pluck(:id)

      questions = Question.where(activity_id: activity_ids)


      @ungraded_ids = questions.not_graded.pluck(:id)
      @graded_ids = questions.graded.pluck(:id)
      @graded_answers = Answer.where(question_id: @graded_ids, user_id: @user.id)
      @ungraded_answers = Answer.where(question_id: @ungraded_ids, user_id: @user.id)

      @posts = lecture_posts.where(user_id: @user.id)
      @comment_count = Comment.where(post_id: post_ids, user_id: @user.id).count

      @counts = SentimentRecord.where(activity_id: activity_ids, user_id: @user.id).group(:sentiment_id).count
      sent_ids = []
      @course.lectures.each do |lecture|
        sent_ids += lecture.sentiments.pluck(:id)
      end
      @sentiments = Sentiment.where(id: sent_ids.uniq).pluck(:id, :title)
      @colors = Sentiment.where(id: sent_ids.uniq).pluck(:color)
      @messages = SentimentManager.getUserCourseMessages(sent_ids.uniq, activity_ids, @user)

      render 'stats_student'
    end
  end

  def enrolled
    @page = 'enrolled'
    @students = (@course.students.sort_by &:first_name)

    @instructors = (@course.instructors.sort_by &:first_name)

    @enrollment = CourseEnrollment.where(user_id:@user.id,course_id:@course.id).select(:enrollment_type).first
    @page_libs = [:tablesorter]
    if @enrollment.instructor?
      render 'enrolled_instructor'
    else
      render 'enrolled_student'
    end
  end

  def newPINS
    allPins = []
    Course.select('instructor_pin', 'student_pin').each do |course|
      allPins.push course.instructor_pin
      allPins.push course.student_pin
    end
    pins = []
    while pins.size < 2
      pin = 1000000 + Random.rand(10000000 - 1000000)
      while allPins.include? pin
        pin = 1000000 + Random.rand(10000000 - 1000000)
      end
      pins.push pin
      allPins.push pin
    end
    pins
  end

  def create
    @course = Course.new(course_params)
    pins = newPINS
    @course.instructor_pin = pins[0]
    @course.student_pin = pins[1]
    @course.user_id = @user.id
    respond_to do |format|
      if @course.save
        CourseEnrollment.create(user: @user, course: @course, enrollment_type: 1)
        @lecture = @course.lectures.create(title: 'First Class Meeting', info: 'An automatically created class meeting, you can edit its title and info!', date: Date.today, start_time: @course.lecture_start_time, end_time: @course.lecture_end_time)
        @lecture.activities.create(title: 'First Activity', active: true, goals: 'An automatically created activity, you can edit its title and objectives!')
        format.html { redirect_to @course, notice: "1: The course was successfully created. 2: And we've created the first class meeting and activity!" }
        format.json { render action: 'courses#show', status: :created, location: @course }
      else
        format.html { render action: 'new' }
        format.json { render json: @course.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @announcements = @course.announcements.where(created_at: (Time.now - 1.weeks)..Time.now).reverse
    @studentsCount = @course.students.count
    respond_to do |format|
      if @course.update(course_params)
        format.html { redirect_to @course, notice: 'Course was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @course.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @course.destroy
    redirect_to user_path(@user), notice: 'The course was successfully deleted!'
  end

  private

  # Sets current course
  def set_course
    @course = Course.friendly.find(params[:id])
    unless @course
      redirect_to user_path(@user), alert: "No Course with id:#{params[:id]}."
    end
  end

  def tabIresponder(activity_ids)
    @tab = params[:tab]
    if @start_date && @end_date
      questions = Question.where(activity_id: activity_ids, hidden: false, created_at: @start_date..@end_date)
    else
      questions = Question.where(activity_id: activity_ids, hidden: false)
    end

    @graded_ids = questions.where(graded: true).pluck(:id)
    @ungraded_ids = questions.where(graded: false).pluck(:id)
    @data = {}
    @students.each do |student|
      answers = Answer.where(question_id: @graded_ids, user_id: student.id)
      @data[student.id] = {
        correctCount: answers.correct_grades.count,
        incorrectCount: answers.where.not(grading: 2).count,
        perCorrect: percentage((answers.correct_grades), answers),
        gradedCount: Answer.where(question_id: @graded_ids, user_id: student.id).count,
        ungradedCount: Answer.where(question_id: @ungraded_ids, user_id: student.id).count,
        totalPoints: answers.pluck(:points).select { |point| point != nil }.inject(:+) || 0.0
      }
    end
  end

  def tabAtRisk(activity_ids)
    if params[:percentage] && params[:percentage] != 'undefined' && params[:percentage] != ''
      @percentage = params[:percentage].to_f
    else
      @percentage = 25
    end

    @tab = params[:tab]
    if @start_date && @end_date
      questions = Question.where(activity_id: activity_ids, hidden: false, created_at: @start_date..@end_date)
    else
      questions = Question.where(activity_id: activity_ids, hidden: false)
    end
    @graded_ids = questions.where(graded: true).pluck(:id)
    @data = {}

    @task_ids = Task.where(activity_id: activity_ids, graded: true).pluck(:id)

    @students.each do |student|
      answers = Answer.where(question_id: @graded_ids, user_id: student.id)
      correct = answers.correct_grades.count
      ind_graded = Response.where(task_id: @task_ids, user_id: student.id, individual: true)
      ind_correct = ind_graded.where(grading: 2)
      @data[student.id] = {
        answered: answers.count.to_s + '/' + @graded_ids.size.to_s,
        perAnswered: percentage(answers, @graded_ids),
        perCorrect: percentage(correct, answers),
        ind_answered: ind_graded.count.to_s + '/' + @task_ids.size.to_s,
        ind_percent_answered: percentage(ind_graded, @task_ids),
        ind_percent_correct: percentage(ind_correct, ind_graded)
      }
    end
  end

  def tabForum(activity_ids)
    lecture_posts = Post.where(activity_id: activity_ids, created_at: @start_date..@end_date)
    if @start_date && @end_date
      lecture_posts = Post.where(activity_id: activity_ids, created_at: @start_date..@end_date)
    else
      lecture_posts = Post.where(activity_id: activity_ids)
    end
    post_ids = lecture_posts.pluck(:id)
    @tab = 'forum'
    @data = {}
    @students.each do |student|
      posts = lecture_posts.where(user_id: student.id)
      @data[student.id] = {
        postCount: posts.count,
        questionCount: posts.questions.count,
        noteCount: posts.notes.count,
        privateCount: posts.private_posts.count,
        commentCount: Comment.where(post_id: post_ids, user_id: student.id).count
      }
    end
  end

  def tabAttendance(lecture_ids)
    @tab = 'attendance'
    @students_data = {}
    @lecture_count = lecture_ids.count

    all_attendances = Attendance.where(lecture_id: lecture_ids)
    if @start_date && @end_date
      all_attendances = all_attendances.where(created_at: @start_date..@end_date)
    end
    @attendance_count = all_attendances.count

    @students.each do |student|
      @students_data[student.id] = {}
      attendances = all_attendances.where(user_id: student.id)
      @students_data[student.id][:totals] = attendances.group(:status).count
    end
  end

  def tabFeedback(activity_ids)
    @tab = 'feedback'
    sent_ids = []
    @course.lectures.each do |lecture|
      sent_ids += lecture.sentiments.pluck(:id)
    end
    @sentiments = Sentiment.where(id: sent_ids.uniq)
    @data = {}
    @students.each do |student|
      records = SentimentRecord.where(activity_id: activity_ids, user_id: student.id, created_at: @start_date..@end_date)
      @data[student.id] = {
        counts: records.group(:sentiment_id).count,
        feedCount: records.count,
        messages: SentimentManager.getUserCourseMessages2(sent_ids.uniq, activity_ids, student.id)
      }
    end
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def course_params
    params.require(:course).permit(:demo, :past, :title, :slug, :code, :instructor, :lecture_days, :start_date, :end_date, :school, :semester, :lecture_start_time, :lecture_end_time, :location)
  end
end
