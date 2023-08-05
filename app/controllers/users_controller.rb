# app/controllers/users_controller.rb
class UsersController < ApplicationController
    before_action :authenticate_user, only: [:profile, :my_posts, :follow_user, :add_like, :add_comment, :recommended_posts, :similar_author_posts, :subscribe, :show]

    #Creating a new User
    def create
        author = Author.find_or_create_by(name: user_params[:name]) # Create a new author based on the user's name
        @user = User.new(
          name: user_params[:name],
          email: user_params[:email],
          password: user_params[:password],
          author: author,
          interests: user_params[:interests],
          specializations: user_params[:specializations],
          expires_at: Time.now,
          last_seen: Time.now
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

    def recommended_posts
      interests_array = current_user.interests.split(',')
      recommended_post = Article.where(genre: interests_array)

      response = recommended_post.map do |article|
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
      render json: response
    end

    def allTopics
      unique_genres = Article.distinct.pluck(:genre)
      render json: unique_genres
    end

    def similar_author_posts
      specializations_array = current_user.specializations.split(',')
      request_users = []

      request_users - User.select do |user|
        if user.specializations.nil?
          false
        else
          user_specializations_array = user.specializations.split(',')
          !(specializations_array & user_specializations_array).empty?
        end
      end



      articles = []

      request_users.each do |user|
        author = user.author
        article_ids = author&.article_ids || []

        article_ids.each do |article_id|
          article = Article.find_by(id: article_id)
          articles.push(article)
        end
      end

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
      render json: response
    end

    def subscribe
      subscription_plan = params[:subscription_plan]
      case subscription_plan
      when 'free'
        current_user.update(subscription_plan: 'free', remaining_posts: 1, expires_at: Time.now + 1.month)
      when '3_posts'
        # Implement payment logic using Razorpay API to charge $3
        # Set the subscription_plan to '3_posts' and remaining_posts to 3
        current_user.update(subscription_plan: '3_posts', remaining_posts: 3, expires_at: Time.now + 1.month)
      when '5_posts'
        # Implement payment logic using Razorpay API to charge $5
        # Set the subscription_plan to '5_posts' and remaining_posts to 5
        current_user.update(subscription_plan: '5_posts', remaining_posts: 5, expires_at: Time.now + 1.month)
      when '10_posts'
        # Implement payment logic using Razorpay API to charge $10
        # Set the subscription_plan to '10_posts' and remaining_posts to 10
        current_user.update(subscription_plan: '10_posts', remaining_posts: 10, expires_at: Time.now + 1.month)
      else
        render json: { error: 'Invalid subscription plan' }, status: :unprocessable_entity
        return
      end

      render json: { message: 'Subscription successful' }, status: :ok
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def reset_remaining_posts
      current_user.update(remaining_posts: current_user.subscription_plan.to_i)
      render json: { message: 'Remaining posts reset' }, status: :ok
    end

    def show
      if !current_user
        render json: { message: 'Please login to see the article' }
        return
      end

      article = Article.find_by(id: params[:id])

      if article

        current_time = Time.now

        if current_user.last_seen.to_date < current_time.to_date
          current_user.update(remaining_posts: current_user.subscription_plan.to_i)
        end

        if current_user.expires_at < current_time
          current_user.update(subscription_plan: 'free', remaining_posts: 1, expires_at: current_time.now + 1.month)
        end

        if current_user.remaining_posts == 0
          render json: {error: 'daily limit reached!'}
          return
        end

        article.increment!(:views)

        current_user.update(last_seen: current_time)
        current_user.decrement!(:remaining_posts)
        current_user.save
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
          views: article.views,
          remaining_posts: current_user&.remaining_posts || 1,
          subscription_plan: current_user&.subscription_plan || 'free'
        }


        render json: response, status: :ok
      else
        render json: { error: 'Article not found' }, status: :not_found
      end
    end


    private

    # def author_params
    #   params.permit(:name)
    # end

    def user_params
      params.permit(:name, :email, :password, :password_confirmation, :interests, :specializations)
    end

  end
