# frozen_string_literal: true

class AnswersController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => :create
  before_action :set_answer, only: [:show, :edit, :update, :destroy]
  before_action :set_user
  before_action :set_context
  before_action :check_access, only: [:grade, :multiple_grade]

  # GET /questions/new
  def new
    @answer = Answer.new
  end

  # GET /questions/1/edit
  def edit
  end

  def index
    redirect_to responses_course_lecture_activity_question_path(@course, @lecture, @activity, @question, :tab => 'responses')
  end

  def grade
    @enrollment = CourseEnrollment.where(user_id: @user.id, course_id: @course.id).select(:enrollment_type).first
    @tab = "responses"
    ids = answer_params[:ids].split(":").collect { |id| id.to_i }
    points = answer_params[:points] == '' ? nil : answer_params[:points].to_f
    Answer.where(:id => ids).update_all(grading: answer_params[:grading].to_i, comments: answer_params[:comments], points: points)
    redirect_to responses_course_lecture_activity_question_path(@course, @lecture, @activity, @question)
  end

  # POST /courses/:course_id/lectures/:lecture_id/activities/:activity_id/questions/:question_id/answers/multiple_grade
  def multiple_grade
    ids = []
    params[:answer_ids].each { |k, v| ids << k if v.present? }
    @enrollment = CourseEnrollment.where(user_id: @user.id, course_id: @course.id).select(:enrollment_type).first
    @tab = 'responses'
    points = params[:points] == '' ? nil : params[:points].to_f
    Answer.where(id: ids).update_all(grading: params[:grading].to_i, comments: params[:comments], points: points)
    redirect_to responses_course_lecture_activity_question_path(@course, @lecture, @activity, @question)
  end

  def review
    answer_ids = answer_params[:ids].split(":").collect { |id| id.to_i }
    existing_reviews = Review.where(answer_id: answer_ids, user_id: @user.id)
    
    other_answer_ids = answer_ids - existing_reviews.pluck(:answer_id)
    existing_reviews.update_all(grading: answer_params[:grading].to_i, comments: answer_params[:comments])
    other_answer_ids.each do |id|
      Review.create(user_id: @user.id, answer_id: id, grading: answer_params[:grading].to_i, comments: answer_params[:comments])
    end

    #Update Review Counts
    answer_ids = @question.answers.pluck(:id)
    review_count = Review.where(answer_id: answer_ids).count
    ActionCable.server.broadcast('update_reviewsCount_' + @activity.id.to_s, { question_id: @question.id, reviewsCount: review_count })

    participated(@lecture,@user)

    redirect_to responses_course_lecture_activity_question_path(@course, @lecture, @activity, @question, :tab => 'reviews')
  end

  # POST /questions
  # POST /questions.json
  def create
    @enrollment = CourseEnrollment.where(user_id: @user.id, course_id: @course.id).select(:enrollment_type).first
    # @questions = @activity.questions
    @answer = Answer.find_by(user_id: @user.id, question_id: @question.id)

    participated(@lecture,@user)

    if @answer
      @answer.given = (@question.qn_type == 'SimpleText' or @question.qn_type == 'Numeric') ? answer_params[:given].strip : answer_params[:given]
    else
      @answer = Answer.new(answer_params)
      @answer.given = @answer.given.strip if (@question.qn_type == 'SimpleText' or @question.qn_type == 'Numeric')
      @answer.user_id = @user.id
      @answer.question_id = @question.id
    end

    @answer.review_grading

    if @answer.save
      ActionCable.server.broadcast('update_showResponsesCount_' + @question.id.to_s, { responsesCount: @question.answers.count })

      ActionCable.server.broadcast('update_responsesCount_' + @activity.id.to_s, { question_id: @question.id, responsesCount: @question.answers.count })

      redirect_to course_lecture_activity_questions_path, notice: 'Answer was successfully submitted.'
    else
      redirect_to course_lecture_activity_questions_path, alert: 'Submission failed. Please retry'
    end
  end

  # PATCH/PUT /questions/1
  # PATCH/PUT /questions/1.json
  def update
    respond_to do |format|
      if @answer.update(answer_params)
        participated(@lecture,@user)
        format.html { redirect_to course_lecture_activity_questions_path, notice: 'Answer was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { redirect_to course_lecture_activity_questions_path, alert: 'Submission failed. Please retry' }
        format.json { render json: @answer.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /questions/1
  # DELETE /questions/1.json
  def destroy
    @answer.destroy
    respond_to do |format|
      format.html { redirect_to course_lecture_activity_questions_path }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_answer
    @answer = Answer.find(params[:id])
  end

  def set_context
    @course = Course.friendly.find(params[:course_id])
    @lecture = Lecture.find(params[:lecture_id])
    @activity = Activity.find(params[:activity_id])
    @question = Question.find(params[:question_id])
    @enrollment = CourseEnrollment.where(user_id: @user.id, course_id: @course.id).select(:enrollment_type).first
  end

  # Never trust parameters from the scary Internet, only allow the white list through.
  def answer_params
    params.require(:answer).permit(:ready_for_review, :given, :user_id, :question_id, :grading, :correct, :points, :comments, :ids)
  end
end
