class SavedSearchesController < ApplicationController
  before_action :authenticate
  before_action :ensure_project

  def create
    @saved_search = current_project.saved_searches.build(saved_search_params)
    @saved_search.user = current_user

    respond_to do |format|
      if @saved_search.save
        format.turbo_stream
        format.html { redirect_to plants_path }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.replace("save-search-form-container", partial: "saved_searches/save_form", locals: { query_term: @saved_search.query_term, error: @saved_search.errors.full_messages.first }) }
        format.html { redirect_to plants_path }
      end
    end
  end

  def destroy
    @saved_search = current_project.saved_searches.where(user: current_user).find(params[:id])
    @saved_search.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to plants_path }
    end
  end

  private

  def saved_search_params
    params.require(:saved_search).permit(:name, :query_term)
  end
end
