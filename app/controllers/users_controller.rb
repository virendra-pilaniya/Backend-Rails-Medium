# app/controllers/users_controller.rb
class UsersController < ApplicationController
    before_action :authenticate_user, only: [:profile, :my_posts, :follow_user]

    #Creating a new User
    def create
        author = Author.find_or_create_by(name: user_params[:name]) # Create a new author based on the user's name
        @user = User.new(
          name: user_params[:name],
          email: user_params[:email],
          password: user_params[:password],
          author: author # Associate the user with the author
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



    private

    # def author_params
    #   params.permit(:name)
    # end

    def user_params
      params.permit(:name, :email, :password, :password_confirmation)
    end

  end
