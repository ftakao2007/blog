class ArticlesController < ApplicationController
  def new
    @article = Article.new
    @comment = Comment.new
  end

  def create
    #@article = Article.new(params[:article]).permit(:title, :text)
    @article = Article.new(article_params)
    @comment = Comment.new(comment_params)

    Article.transaction do
      @comment.article = @article
      @article.save!
      @comment.save!
      flash[:notice] = "記事を投稿しました。"
      redirect_to @article
    end
  end

  def show
    @article = Article.find(params[:id])
    #@comment = Comment.find_by(article_id: params[:id])
    @comment = @article.comment
  end

  def index
    @articles = Article.all
  end

  def edit
    @article = Article.find(params[:id])
    @comment = @article.comment
  end

  def update
    @article = Article.new(article_params)
    @comment = Comment.new(comment_params)

    Article.transaction do
      @comment.article = @article
      @article.save!
      @comment.save!
      flash[:notice] = "記事を更新しました。"
      redirect_to @article
    end
  end

  def destroy
    @article = Article.find(params[:id])
    @article.destroy

    redirect_to articles_path
  end

  private

  def article_params
    params.require(:article).permit(:title, :text)
  end

  def comment_params
    params.require(:comment).permit(:commenter, :body)
  end
end
