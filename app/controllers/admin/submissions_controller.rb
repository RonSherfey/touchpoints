class Admin::SubmissionsController < AdminController
  protect_from_forgery only: []
  before_action :set_touchpoint, only: [:index, :show, :flag, :destroy]
  before_action :set_submission, only: [:show, :flag, :destroy]

  def index
    @submissions = @touchpoint.submissions.includes(:organization)
  end

  def show
  end

  def flag
    @submission.update_attribute(:flagged, true)
    respond_to do |format|
      format.html { redirect_to admin_touchpoint_url(@touchpoint), notice: "Submission #{@submission.id} was successfully flagged." }
      format.json { head :no_content }
    end
  end

  def destroy
    ensure_service_manager(service: @touchpoint.service)

    @submission.destroy
    respond_to do |format|
      format.html { redirect_to admin_touchpoint_url(@touchpoint), notice: "Submission #{@submission.id} was successfully destroyed." }
      format.json { head :no_content }
    end
  end


  private

    def set_touchpoint
      @touchpoint = current_user.touchpoints.find(params[:touchpoint_id])
      raise InvalidArgument("Touchpoint does not exist") unless @touchpoint
    end

    def set_submission
      @submission = @touchpoint.submissions.find(params[:id])
    end
end
