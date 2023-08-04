# app/controllers/users_controller.rb
class UsersController < ApplicationController
    before_action :authenticate_user, only: [:profile, :my_posts, :follow_user, :add_like, :add_comment]

    #Creating a new User
    def create
        author = Author.find_or_create_by(name: user_params[:name]) # Create a new author based on the user's name
        @user = User.new(
          name: user_params[:name],
          email: user_params[:email],
          password: user_params[:password],
          author: author # Associate the user with the author
          interests: user_params[:interests]
        )

        if @user.save
          token = JWT.encode({ user_id: @user.id }, Rails.application.secrets.secret_key_base, 'HS256')
          render json: { token: token, message: 'Registration successful. Please log in.' }, status: :created
        else
          render json: { error: @user.errors.full_messages }, status: :unprocessable_entity
        end
    end

    def show_author
      author = User.find_by(name: params[:name])
      render json: author
    end

    # Profile Page
    def profile
        render json: current_user, status: :ok
    end

    #Posts By a Particlar Author
    def my_posts
      author = current_user.author
      article_ids = author&.article_ids || []
      articles = []
      article_ids.each do |article_id|
        article = Article.find_by(id: article_id)
        # articles << article if article
        articles.push(article)
      end
      # articles = Article.all
      response = articles.map do |article|
        {
          id: article.id,
          title: article.title,
          author: article.author,
          description: article.description,
          genre: article.genre,
          image_url: article.image.attached? ? url_for(article.image) : nil,
          created_at: article.created_at,
          updated_at: article.updated_at,
          no_of_likes: article.no_of_likes,
          no_of_comments: article.no_of_comments,
          likes: article.likes,
          comments: article.comments,
          views: article.views
        }
    end
      render json: response, status: :ok
    end

    # Follow a Particular User
    # def follow_user
    #   current_user.following << params[:id]
    #   current_user.save
    #   render json: current_user.following
    # end

    def follow_user
      target_user = User.find_by(id: params[:id])
      if current_user.follow_user(target_user.id)
        flash[:success] = "You are now following #{target_user.name}."
      else
        flash[:error] = "Failed to follow the user."
      end
      render json: current_user.followed_ids
    end

    def add_like
      if current_user.id != params[:user_id].to_i
        render json: {error: 'Please login to like this article.'}, status: :not_found
        return
      end

      article = Article.find_by(id: params[:article_id])

      if article.likes.include?(params[:user_id])
        render json: {error: 'You have already liked this article'}
        return
      end

      if article
        article.increment!(:no_of_likes)
        article.likes.push(params[:user_id])
        article.save

        response = {
          id: article.id,
          title: article.title,
          author: article.author,
          description: article.description,
          genre: article.genre,
          image_url: article.image.attached? ? url_for(article.image) : nil,
          created_at: article.created_at,
          updated_at: article.updated_at,
          no_of_likes: article.no_of_likes,
          no_of_comments: article.no_of_comments,
          likes: article.likes,
          comments: article.comments,
          views: article.views
        }

        render json: response, status: :ok

      else
        render json: { error: 'Article not found' }, status: :not_found
      end

    end

    def add_comment
      if current_user.id != params[:user_id].to_i
        render json: {error: 'Please login to comment on this article.'}, status: :not_found
        return
      end

      article = Article.find_by(id: params[:article_id])


      if article
        article.increment!(:no_of_comments)
        article.comments.push({user_id: params[:user_id], comment_text: params[:comment_text]})
        article.save

        response = {
          id: article.id,
          title: article.title,
          author: article.author,
          description: article.description,
          genre: article.genre,
          image_url: article.image.attached? ? url_for(article.image) : nil,
          created_at: article.created_at,
          updated_at: article.updated_at,
          no_of_likes: article.no_of_likes,
          no_of_comments: article.no_of_comments,
          likes: article.likes,
          comments: article.comments,
          views: article.views
        }

        render json: response, status: :ok

      else
        render json: { error: 'Article not found' }, status: :not_found
      end

    end

    # def recommended_posts

    # end

    private

    # def author_params
    #   params.permit(:name)
    # end

    def user_params
      params.permit(:name, :email, :password, :password_confirmation, :interests)
    end

  end
