class SubmissionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :create
  before_action :cors_check, only: :create
  before_action :set_submission, only: [:show, :edit, :update, :destroy]
  before_action :configure_spam_filter, only: :update

  # GET /submissions
  def index
    @submissions = Submission.all.order(:filter_result).reverse
  end

  # GET /submissions/1
  def show
  end

  # GET /submissions/new
  def new
    @submission = Submission.new
  end

  # GET /submissions/1/edit
  def edit
  end

  # POST /submissions
  def create
    respond_to do |format|
      if @did_save
        # FilterSpamJob.new(@submission, @http_headers).perform_now
        format.html { redirect_to @landing_page, notice: 'Submission was successfully created.' }
        format.json { render :show, status: :created, location: @submission }
      else
        format.html { render :new }
        format.json { render json: @submission.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /submissions/1
  def update
    respond_to do |format|
      if @submission.update(submission_params)
        format.html { redirect_to @submission, notice: @submission_updated_notice }
        format.json { render :show, status: :ok, location: @submission }
      else
        format.html { render :edit }
        format.json { render json: @submission.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /submissions/1
  def destroy
    @submission.destroy
    respond_to do |format|
      format.html { redirect_to submissions_url, notice: 'Submission was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def allowed(request)
      case request.headers['Origin']
      when 'http://davidsolis.me'
        return true
      when 'http://www.davidmazza.com'
        return true
      when 'https://salutant.herokuapp.com'
        return true
      when 'http://notes.soliskit.com'
        return true
      when 'http://salutant.soliskit.com'
        return true
      when request.local?
        return true
      when nil
        return false
      end
    end

    def cors_check
      if allowed(request)
        parse_submission
      else
        render :json => "404 Not Found", :status => 404
      end
    end

    def addressed_to(request)
      case request.headers['Origin']
      when 'http://davidsolis.me'
        return :solis
      when 'http://www.davidmazza.com'
        return :mazza
      when 'http://notes.soliskit.com'
        return :peaking
      when request.local?
        return :peaking
      end
    end

    def parse_submission
      @submission = Submission.new(submission_params)
      @landing_page, @http_headers = request_submission_headers_from(request)
      @did_save = @submission.save

      @submission.update sent_to: addressed_to(request) # Addressed to
      @submission.update headers: @http_headers # Message headers
    end

    def request_submission_headers_from(request)
      # Collect all CGI-style HTTP_ headers except cookies for privacy..
      headers = request.env.select { |k,v| selected_headers.include? k }

      landing_page = request.headers['Origin']
      return landing_page, headers
    end

    def set_submission
      @submission = Submission.find(params[:id])
    end

    def configure_spam_filter
      if params[:submission][:filter_result] != @submission.filter_result
        if params[:submission][:filter_result] == 'spam'
          SubmitSpamJob.new(@submission).perform_now
          @submission_updated_notice = 'Spam successfully reported.'
        elsif params[:submission][:filter_result] == 'not_spam'
          SubmitHamJob.new(@submission).perform_now
          @submission_updated_notice = 'False positives successfully reported.'
        end
      else
        @submission_updated_notice = 'Submission was successfully updated.'
      end
    end

    def selected_headers
      headers = ['HTTP_VIA', 'HTTP_HOST', 'HTTP_ACCEPT', 'HTTP_REFERER', 'HTTP_VERSION', 'HTTP_CONNECTION', 'HTTP_USER_AGENT', 'HTTP_CONNECT_TIME', 'HTTP_X_REQUEST_ID', 'HTTP_ACCEPT_CHARSET', 'HTTP_ACCEPT_ENCODING', 'HTTP_ACCEPT_LANGUAGE', 'HTTP_X_FORWARDED_FOR', 'HTTP_X_REQUEST_START', 'HTTP_TOTAL_ROUTE_TIME', 'HTTP_X_FORWARDED_PORT', 'HTTP_X_FORWARDED_PROTO', 'ORIGIN', 'GATEWAY_INTERFACE', 'QUERY_STRING', 'REMOTE_ADDR', 'REMOTE_HOST', 'REMOTE_PORT', 'REMOTE_USER', 'REQUEST_URI', 'REDIRECT_REMOTE_USER', 'SERVER_ADDR', 'SERVER_NAME', 'SERVER_ADMIN', 'SERVER_PORT', 'SERVER_SIGNATURE', 'SERVER_SOFTWARE', 'SERVER_PROTOCOL']

      return headers
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def submission_params
      params.require(:submission).permit(:name, :email, :content, :body, :phone, :filter_result)
    end
end
