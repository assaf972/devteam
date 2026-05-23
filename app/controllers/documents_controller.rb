class DocumentsController < ApplicationController
  before_action :set_project, only: [ :index, :new, :create ]
  before_action :set_document, only: [ :show, :edit, :update, :destroy ]

  def index
    @documents = @project.documents.includes(:author)
    @documents = @documents.where(doc_type: params[:doc_type]) if params[:doc_type].present?
    @documents = @documents.order(updated_at: :desc)
    @grouped   = @documents.group_by(&:doc_type)
  end

  def show; end

  def new
    @document = @project.documents.build(author: current_user)
  end

  def create
    @document = @project.documents.build(document_params.merge(author: current_user))
    if @document.save
      redirect_to @document, notice: "Document created."
    else
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

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_document
    @document = Document.find(params[:id])
    @project  = @document.project
  end

  def document_params
    params.require(:document).permit(:title, :content, :doc_type, :summary, :version_number, :tag_list)
  end
end
