class ProjectsController < ApplicationController
  before_filter :set_breadcrumbs
  has_scope :tagged_with, as: :tag

  def index
  end

  def new
    unless event.enable_project_creation
      flash.alert = 'Projects can no longer be created here for this event. Please get in touch if you\'d like to add a project here.'
      redirect_to event_path(event)
    end

    breadcrumbs.add "New project", new_event_project_path(event)
  end

  def create
    project.assign_attributes(project_params(:create))

    if project.save
      flash.notice = 'Thanks for submitting your project.'
      redirect_to event_project_url(event, project)
    else
      breadcrumbs.add "New project", new_event_project_path(event)
      render action: :new
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json
    end
  end

  def edit
    breadcrumbs.add "Edit project", edit_event_project_path(event, project)
  end

  def update
    submitted_secret = project_params.delete(:submitted_secret)

    if project.update_attributes_with_secret(submitted_secret, project_params)
      flash.notice = 'Your changes have been saved.'
      redirect_to event_project_url(event, project)
    else
      breadcrumbs.add "Edit project", edit_event_project_path(event, project)
      render action: :edit
    end
  end

  def event
    @event ||= Event.find_by_slug(params[:event_id]) || not_found
  end
  helper_method :event

  def project
    if params[:id]
      @project ||= event.projects.find_by_slug(params[:id]) || not_found
    else
      @project ||= Project.new(event: event)
    end
  end
  helper_method :project

  def projects
    @projects ||= apply_scopes(event.projects)
  end
  helper_method :projects

  private
    def set_breadcrumbs
      breadcrumbs.add event.title, event_path(event)

      if project.persisted?
        if event.use_centres?
          breadcrumbs.add project.centre.name, event_centre_path(event, project.centre.slug) if event.use_centres
        end

        breadcrumbs.add project.title, event_project_path(event, project)
      end
    end

    def project_params(action = nil)
      attributes = [:title, :team, :url, :image, :description, :twitter,
                    :github_url, :tag_list_with_hashes, :code_url, :centre_id,
                    :submitted_secret]

      if action == :create
        attributes << :secret
      end

      params.require(:project).permit(*attributes)
    end
end
