class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_post, only: [:show, :edit, :update, :destroy]
  before_action :authorize_post!, only: [:edit, :update, :destroy]

  def index
    @category = params[:category].presence
    @q = Post.ransack(params[:q])
    posts = @q.result.includes(:user).recent
    posts = posts.by_category(@category) if @category.present? && Post.categories.key?(@category)
    @posts = posts.page(params[:page]).per(12)
  end

  def show
    @post.increment_views!
    @comments = []  # 향후 댓글 기능 추가용
  end

  def new
    @post = Post.new
  end

  def create
    @post = current_user.posts.build(post_params)
    if @post.save
      redirect_to community_path, notice: "게시글이 등록되었어요!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @post.update(post_params)
      redirect_to post_path(@post), notice: "게시글이 수정되었어요!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
    redirect_to community_path, notice: "게시글이 삭제되었어요."
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def authorize_post!
    unless @post.user == current_user || current_user.admin?
      redirect_to community_path, alert: "권한이 없어요."
    end
  end

  def post_params
    params.require(:post).permit(:title, :content, :category, :image)
  end
end
