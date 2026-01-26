class ProjectsController < ApplicationController
  before_action :set_project, only: [:show, :edit, :update]

  before_action :authenticate, only: [:new, :create]
  before_action :authorize_viewer, only: [:show]
  before_action :authorize_editor, except: [:show, :index, :new, :create]
  before_action :require_advanced_mode, only: [:show, :edit, :new]

  def index
    # Non-advanced users should be auto-routed to their single project
    if current_user && !current_user.advanced_mode?
      project = current_user.projects.first || Collaboration.find_by(user: current_user)&.project
      if project
        set_current_project(project)
        return redirect_to plants_path
      end
    end

    if !current_user&.admin?
      ownerships = current_user&.projects || []
      collaborations = Collaboration.where(user: current_user).map &:project
      @projects = ownerships + collaborations
    else
      @projects = Project.all
    end
  end

  def show

  end

  def new
    @project = Project.new
  end

  def create
    @project = Project.new(project_params)
    @project.owner = current_user
    respond_to do |format|
      if @project.save
        set_current_project @project
        format.html { redirect_to plants_path, notice: t('projects.create_success') }
        format.json { render :show, status: :created, location: @project }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit

  end

  def update
    respond_to do |format|
      if @project.update(project_params)
        format.html { redirect_to project_url(@project), notice: t('projects.update_success') }
        format.json { render :show, status: :ok, location: @project }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  def add_collaborator
    user = User.find_by_email collaborator_params[:email]
    if user.nil?
      return redirect_to project_path(current_project), alert: t('errors.invalid_email')
    end
    if current_project.users.include? user
      return redirect_to project_path(current_project), alert: t('errors.user_already_added')
    end
    c = current_project.add_user_with_role user, collaborator_params[:role]
    if c
      redirect_to project_path(current_project), notice: t('projects.messages.add_collaborator_success')
    else
      redirect_to project_path(current_project), alert: t('projects.messages.add_collaborator_error')
    end
  end
  def remove_collaborator
    user = User.find_by id: params[:user_id]
    collab = current_project.remove_user user
    if collab.destroyed?
      redirect_to current_project, notice: t('projects.messages.remove_collaborator_success')
    else
      redirect_to current_project, alert: t('projects.messages.remove_collaborator_error')
    end
  end

  private

  def require_advanced_mode
    unless current_user&.advanced_mode? || current_user&.admin?
      redirect_to plants_path
    end
  end

  def set_project
    @project = Project.find params[:id]
    if @project.users.include? current_user
      set_current_project @project
    end
  end

  def project_params
    params.require(:project).permit(:name, :api_key)
  end

  def collaborator_params
    params.require(:collaborator).permit(:email, :role, :user_id)
  end
end