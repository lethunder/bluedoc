class DocsController < Users::ApplicationController
  before_action :authenticate_user!, only: %i[new edit create update destroy versions revert]

  before_action :set_user
  before_action :set_repository
  before_action :set_doc, except: %i[index new create]

  # GET /docs
  # GET /docs.json
  def index
    authorize! :read, @repository

    @docs = Doc.all
  end

  # GET /docs/1
  # GET /docs/1.json
  def show
    if @doc.blank?
      authorize! :read, @repository
    else
      authorize! :read, @doc
    end

    render "show", layout: "reader"
  end

  # GET /docs/new
  def new
    authorize! :create_doc, @repository

    @doc = Doc.new
    @doc.title = "New Document"
    @doc.slug = Time.now.to_i.to_s(36)
    render :new, layout: "editor"
  end

  # GET /docs/1/edit
  def edit
    authorize! :update, @doc
    render :new, layout: "editor"
  end

  # POST /docs
  # POST /docs.json
  def create
    @doc = Doc.new(doc_params)
    @doc.repository_id = @repository.id
    @doc.creator_id = current_user.id
    @doc.last_editor_id = current_user.id

    authorize! :create, @doc

    # FIXME: check repo permission
    respond_to do |format|
      if @doc.save
        format.html { redirect_to @doc.to_path, notice: 'Doc was successfully created.' }
        format.json { render :show, status: :created, location: @doc }
      else
        format.html { render :new, layout: "editor" }
        format.json { render json: @doc.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /docs/1
  # PATCH/PUT /docs/1.json
  def update
    authorize! :update, @doc
    @doc.last_editor_id = current_user.id

    respond_to do |format|
      if @doc.update(doc_params)
        format.html { redirect_to @doc.to_path, notice: 'Doc was successfully updated.' }
        format.json { render :show, status: :ok, location: @doc }
      else
        format.html { render :edit, layout: "editor" }
        format.json { render json: @doc.errors, status: :unprocessable_entity }
      end
    end
  end

  def raw
    authorize! :read, @doc

    render plain: @doc.body_plain
  end

  def versions
    authorize! :update, @doc

    @current_version = @doc.versions.includes(:user).first
    @versions = @doc.versions.where("id <> ?", @current_version.id).includes(:user).page(params[:page]).per(7)
    render "versions", layout: "reader"
  end

  def revert
    authorize! :update, @doc

    version_id = params.permit(:version_id)[:version_id]
    if @doc.revert(version_id, user_id: current_user.id)
      redirect_to @doc.to_path, notice: "Doc was successfully reverted."
    else
      redirect_to @doc.to_path("/versions"), alert: "Revert failed, please check a exists version."
    end
  end

  # DELETE /docs/1
  # DELETE /docs/1.json
  def destroy
    authorize! :destroy, @doc

    @doc.destroy
    respond_to do |format|
      format.html { redirect_to @repository.to_path, notice: 'Doc was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    def set_repository
      @repository = Repository.find_by_slug!(params[:repository_id])
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_doc
      @doc = @repository.docs.find_by_slug(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def doc_params
      params.require(:doc).permit(:title, :draft_title, :body, :draft_body, :slug)
    end
end
