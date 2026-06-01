class DocumentsController < ApplicationController
  before_action :set_project, only: [ :index, :new, :create, :templates ]
  before_action :set_document, only: [ :show, :edit, :update, :destroy, :save_as_template, :new_from_template, :raw ]

  def index
    @documents = @project.documents.regular.includes(:author)
    @documents = @documents.where(doc_type: params[:doc_type]) if params[:doc_type].present?
    @documents = @documents.order(updated_at: :desc)
    @grouped   = @documents.group_by(&:doc_type)
  end

  def templates
    @templates = @project.documents.templates.includes(:author).order(updated_at: :desc)
  end

  def show
    if @document.content.lstrip.start_with?("<!DOCTYPE", "<html")
      response.headers["X-Frame-Options"] = "SAMEORIGIN"
      render html: @document.content.html_safe, layout: false, content_type: "text/html"
    end
  end

  def raw
    response.headers["X-Frame-Options"] = "SAMEORIGIN"
    render html: @document.content.html_safe, layout: false, content_type: "text/html"
  end

  def new
    @document  = @project.documents.build(author: current_user)
    @templates = @project.documents.templates.order(:title)
  end

  def new_from_template
    @project  = @document.project
    @new_doc  = @document.duplicate_from_template
    @templates = @project.documents.templates.order(:title)
    render :new
  end

  def create
    @document = @project.documents.build(document_params.merge(author: current_user))
    if @document.save
      redirect_to @document, notice: "Document created."
    else
      @templates = @project.documents.templates.order(:title)
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @document.update(document_params)
      redirect_to @document, notice: "Document updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @document.destroy
    redirect_to project_documents_path(@project), notice: "Document deleted."
  end

  def save_as_template
    @document.update!(is_template: true)
    redirect_to @document, notice: "\"#{@document.title}\" saved as template."
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_document
    @document = Document.find(params[:id])
    @project  = @document.project
  end

  def document_params
    params.require(:document).permit(:title, :content, :doc_type, :summary, :version_number, :tag_list, :is_template, :template_id)
  end
end
