class DeploymentsController < ApplicationController
  before_action :set_project
  before_action :set_deployment, only: [ :show ]

  def index
    @deployments = @project.deployments
                            .includes(:deployed_by, :client_account)
                            .order(created_at: :desc)
    @deployments = @deployments.where(environment: params[:environment]) if params[:environment].present?
    @deployments = @deployments.where(status: params[:status]) if params[:status].present?
  end

  def show; end

  def new
    @deployment = @project.deployments.build(deployed_by: current_user)
    @client_accounts = ClientAccount.order(:name)
  end

  def create
    @deployment = @project.deployments.build(deployment_params.merge(deployed_by: current_user, deployed_at: Time.current))
    if @deployment.save
      redirect_to @deployment, notice: "Deployment record created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_deployment
    @deployment = @project.deployments.find(params[:id])
  end

  def deployment_params
    params.require(:deployment).permit(
      :version, :environment, :status, :machine_name,
      :client_account_id, :deploy_type, :notes
    )
  end
end
