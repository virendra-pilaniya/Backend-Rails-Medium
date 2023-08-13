# app/controllers/users_controller.rb
class UsersController < ApplicationController
  before_action :authenticate_user, only: [:update_user, :delete_user, :create_article_in_list, :view_list, :save_article_for_later, :saved_articles, :profile, :my_posts, :follow_user, :add_like, :add_comment, :recommended_posts, :similar_author_posts, :subscribe_without_payment, :show, :create_draft, :update_draft, :my_drafts]

  #Creating a new User
  def create
      if user_params[:password] != user_params[:password_confirmation]
        render json: { error: "Password & confirm password don't match" }, status: :unprocessable_entity
      end

      author = Author.find_or_create_by(name: user_params[:name]) # if author is present good, otherwise Create a new author based on the user's name
      @user = User.new(
        name: user_params[:name],
        email: user_params[:email],
        password: user_params[:password],
        author: author,
        interests: user_params[:interests],
        specializations: user_params[:specializations],
        expires_at: Time.now,
        last_seen: Time.now,
        list: []
      )

      if @user.save
        token = JWT.encode({ user_id: @user.id }, Rails.application.secrets.secret_key_base, 'HS256')
        render json: { token: token, message: 'Registration successful. Please log in.' }, status: :created
      else
        render json: { error: @user.errors.full_messages }, status: :unprocessable_entity
      end
  end

  #updting the user
  def update_user
    user = current_user

    if user.update(user_params)
      user.articles.each do |article|
        article.update_author_name(user.name)
      end

      render json: user, status: :ok
    else
      render json: { error: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  #deleting the user
  def delete_user
    user = current_user

    if user.destroy
      user.articles.each do |article|
        article.destroy
      end

      render json: { message: 'User deleted successfully' }, status: :ok
    else
      render json: { error: 'Failed to delete user' }, status: :unprocessable_entity
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

  def show_revision_history
    articles = Article.find_by(id: params[:article_id])

    response = articles.map do |article|
      {
        revision_history: article.revision_history,
        id: article.id
      }
    end
    render json: response, status: :ok
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
        views: article.views,
        reading_time: article.reading_t,
        revision_history: article.revision_history
      }
  end
    render json: response, status: :ok
  end

  #Follow user
  def follow_user
    target_user = User.find_by(id: params[:id])
    if current_user.follow_user(target_user.id)
      flash[:success] = "You are now following #{target_user.name}."
    else
      flash[:error] = "Failed to follow the user."
    end
    render json: current_user.followed_ids
  end

  #Adding likes by logged - in user
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
        views: article.views,
        reading_time: article.reading_t,
        revision_history: article.revision_history
      }

      render json: response, status: :ok

    else
      render json: { error: 'Article not found' }, status: :not_found
    end

  end

  #Adding comments by logged - in user
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
        views: article.views,
        reading_time: article.reading_t,
        revision_history: article.revision_history
      }

      render json: response, status: :ok

    else
      render json: { error: 'Article not found' }, status: :not_found
    end

  end

  #Recommended Posts, it works on the priciple of matching articles's genre with user's interests
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
        views: article.views,
        reading_time: article.reading_t,
        revision_history: article.revision_history
      }
    end
    render json: response
  end

  #Providing unique genres of all articles
  def allTopics
    unique_genres = Article.distinct.pluck(:genre)
    render json: unique_genres
  end

  def similar_author_posts
    specializations_array = current_user.specializations.split(',')
    request_users = []

    request_users = User.select do |user|
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
        views: article.views,
        reading_time: article.reading_t,
        revision_history: article.revision_history
      }
    end
    render json: response
  end

  #dummy function to give subscription to a user without going through payment model, payment model + subscription is present in payments controller
  def subscribe_without_payment
    subscription_plan = params[:subscription_plan]
      case subscription_plan
      when 'free'
        current_user.update(subscription_plan: 'free', remaining_posts: 1, expires_at: Time.now + 1.month)
      when '3_posts'

        current_user.update(subscription_plan: '3_posts', remaining_posts: 3, expires_at: Time.now + 1.month)
      when '5_posts'
        current_user.update(subscription_plan: '5_posts', remaining_posts: 5, expires_at: Time.now + 1.month)
      when '10_posts'
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

  #show function for logged - in user to see any posts, if he has remaining any views in his subscription, then he can see the article, provided it's id.
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
        current_user.update(subscription_plan: 'free', remaining_posts: 1, expires_at: current_time + 1.month)
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

  #creating a draft.
  def create_draft
    permitted_params = article_param

    author = Author.find_or_create_by(name: permitted_params[:author])

    article = Article.new(
          title: permitted_params[:title],
          description: permitted_params[:description],
          genre: permitted_params[:genre],
          author: author,
          no_of_likes: 0,
          no_of_comments: 0,
          likes: [],
          comments: [],
          is_draft: true
    )

    article.image.attach(permitted_params[:image]) if permitted_params[:image].present?

      if article.save

          author.update(article_ids: author.article_ids << article.id)
          update_revision_history(article, "Draft created at #{Time.now}\n")

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
          is_draft: article.is_draft
          }

          render json: response, status: :created
      else
          render json: { error: 'Failed to create the Draft' }, status: :unprocessable_entity
      end
  end

  #Updating draft.
  def update_draft
    article = Article.find_by(id: params[:id])

    unless article
      render json: { error: 'Draft article not found' }, status: :not_found
      return
    end

    # Ensuring the article belongs to the current user and is a draft
    if article.author_id != current_user.author_id || !article.is_draft
      render json: { error: 'You do not have permission to update this draft' }, status: :unauthorized
      return
    end

    permitted_params = article_param.except(:author)

      if article.update(permitted_params)

          update_revision_history(article, "Draft updated at #{Time.now}\n")

          response = {
          id: article.id,
          title: article.title,
          author: article.author.name,
          description: article.description,
          genre: article.genre,
          image_url: article.image.attached? ? url_for(article.image) : nil,
          created_at: article.created_at,
          updated_at: article.updated_at,
          no_of_likes: article.no_of_likes,
          no_of_comments: article.no_of_comments,
          likes: article.likes,
          comments: article.comments
          }

          render json: response
      else
          render json: { error: 'Failed to update the Draft' }, status: :unprocessable_entity
      end
  end

  #Deleting draft.
  def delete_draft
    article = Article.find_by(id: params[:id])

    if article
      author = article.author

      # Destroy the associated image along with the article
      article.image.purge if article.image.attached?

      # Destroy the article
      article.destroy

      # Removig the article's ID from the author's article_ids array
      author.update(article_ids: author.article_ids - [params[:id].to_i])

      render json: { message: 'Draft deleted successfully!' }, status: :ok
    else
      render json: { error: 'Draft not found' }, status: :not_found
    end
end

  #showing all the drafts for a logged - in user
  def my_drafts
    # Retrieve all draft articles of the current user
    articles = Article.where(author_id: current_user.author_id, is_draft: true)

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
        comments: article.comments
      }
    end

    render json: response
  end

  #updating revision history for a article
  def update_revision_history(article, revision_text)
    article.update(revision_history: "#{article.revision_history}#{revision_text}")
  end

  #retreiving article which are saved for later for a logged in user
  def saved_articles
    user = current_user

    saved_articles = user.saved_articles.includes(article: :author)

    response = saved_articles.map do |article|
      article = {
        id: article.id,
        title: article.title,
        author: article.author.name,
        description: article.description,
        genre: article.genre,
        image_url: article.image.attached? ? url_for(article.image) : nil,
        created_at: article.created_at,
        updated_at: article.updated_at,
        no_of_likes: article.no_of_likes,
        no_of_comments: article.no_of_comments,
        likes: article.likes,
        comments: article.comments
      }
    end

    render json: response
  end

  #save a article for later for a logged in user
  def save_article_for_later
    user = current_user
    article = Article.find(params[:article_id])

    saved_article = SavedArticle.new(user: user, article: article)
    saved_article.save

    render json: { message: 'Article saved for later' }
  end

  #viewing the list made by the loggedin user.
  def view_list
    user = current_user
    render json: { list: user.list || [] }
  end

  #creating list for a loggedin user, which compreises of article id and title
  def create_article_in_list
    user = current_user

    article = Article.find(params[:article_id])

    user.list ||= []
    user.list << { id: article.id, title: article.title }

    if user.save
      render json: { message: 'Article added to the list' }
    else
      render json: { error: 'Failed to add the article to the list' }, status: :unprocessable_entity
    end
  end

  #sharing the list created by the user, whose id will be provided in params
  def share_list
    user = User.find_by(id: params[:user_id])

    if user
      render json: { list: user.list }, status: :ok
    else
      render json: { error: 'User not found' }, status: :not_found
    end
  end

  private

  def user_params
    params.permit(:name, :email, :password, :password_confirmation, :interests, :specializations)
  end

  def article_param
    params.permit(:title, :author, :description, :genre, :image)
  end

end
