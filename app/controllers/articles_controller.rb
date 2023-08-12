class ArticlesController < ApplicationController

  before_action :authenticate_user, only: [:create, :update, :delete]

  #creating article
  def create
    # Permiting only the specific fields
   permitted_params = article_params

   author = Author.find_by(id: current_user.author_id)

   # I am assuming it will take 225 words pr minute
   words_per_minute = 225.0
   word_count = permitted_params[:description].split.size
   reading_time = (word_count.to_f / words_per_minute)

   article = Article.new(
       title: permitted_params[:title],
       description: permitted_params[:description],
       genre: permitted_params[:genre],
       author: author,
       no_of_likes: 0,
       no_of_comments: 0,
       likes: [],
       comments: [],
       reading_t: reading_time,
       is_draft: false,
       revision_history: "Created article with title #{permitted_params[:title]}, Initial version created at #{Time.now}\n"
   )

   article.image.attach(permitted_params[:image]) if permitted_params[:image].present?

   if article.save

       author.update(article_ids: author.article_ids << article.id)

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
       is_draft: article.is_draft,
       reading_t: reading_time,
       revision_history: article.revision_history
       }

       render json: response, status: :created
   else
       render json: { error: 'Failed to create the article' }, status: :unprocessable_entity
   end
end

#updating article
def update
   article = Article.find_by(id: params[:id])

   if article.author.id != current_user.author_id
    render json: { error: 'This aint your article' }, status: :not_found
    return
   end

   unless article
     render json: { error: 'Article not found' }, status: :not_found
     return
   end


   permitted_params = article_params.except(:author)

   if article.update(permitted_params)

       update_revision_history(article, "Article with title #{article.title} and Id: #{article.id} Updated at #{Time.now}\n")

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
       comments: article.comments,
       reading_time: article.reading_t,
       revision_history: article.revision_history
       }

       render json: response
   else
       render json: { error: 'Failed to update the article' }, status: :unprocessable_entity
   end
end

   #deleting article
   def delete
   article = Article.find_by(id: params[:id])

   if article.author.id != current_user.author_id
    render json: { error: 'This aint your article' }, status: :not_found
    return
   end

   if article

     author = article.author

     article.image.purge if article.image.attached?

     article.destroy

     # Removing the article's id from the author's article_ids array
     author.update(article_ids: author.article_ids - [params[:id].to_i])

     render json: { message: 'Article deleted successfully!' }, status: :ok
   else
     render json: { error: 'Article not found' }, status: :not_found
   end
end
      #showing all the articles
      def all
        articles = Article.includes(image_attachment: :blob)
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
            reading_time: article.reading_t,
            revision_history: article.revision_history
          }
        end
        render json: response
      end

    #filtering the articles
    def filter
      author_name = params.fetch(:author, "")
      title = params.fetch(:title, "")
      min_likes = params.fetch(:min_likes, nil) # The minimum number of likes
      max_likes = params.fetch(:max_likes, nil) # The maximum number of likes
      min_comments = params.fetch(:min_comments, nil) # The minimum number of comments
      max_comments = params.fetch(:max_comments, nil) # The maximum number of comments

      articles = Article.all

      if author_name.present?
        author = Author.find_by("lower(name) = ?", author_name.downcase)

        articles = articles.where(author: author) if author
      end

      if title.present?
        articles = articles.where(title: title)
      end

      if min_likes.present? && max_likes.present?
        articles = articles.where(no_of_likes: min_likes..max_likes)
      elsif min_likes.present?
        articles = articles.where("no_of_likes >= ?", min_likes)
      elsif max_likes.present?
        articles = articles.where("no_of_likes <= ?", max_likes)
      end

      if min_comments.present? && max_comments.present?
        articles = articles.where("no_of_comments >= ? AND no_of_comments <= ?", min_comments, max_comments)
      elsif min_comments.present?
        articles = articles.where("no_of_comments >= ?", min_comments)
      elsif max_comments.present?
        articles = articles.where("no_of_comments <= ?", max_comments)
      end

      response = articles.map do |article|
        {
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
          comments: article.comments,
          reading_time: article.reading_t,
          revision_history: article.revision_history
        }
      end

      render json: response
    end

    #searching for articles
    def search
      title = article_search_params[:title].presence
      description = article_search_params[:description].presence
      genre = article_search_params[:genre].presence
      author_name = article_search_params[:author].presence

      articles = Article.all

      articles = articles.where("lower(title) LIKE ?", "%#{title.downcase}%") if title
      articles = articles.where("lower(description) LIKE ?", "%#{description.downcase}%") if description
      articles = articles.where("lower(genre) LIKE ?", "%#{genre.downcase}%") if genre

      if author_name.present?
        author = Author.find_by("lower(name) = ?", author_name.downcase)

        articles = articles.where(author_id: author.id) if author
      end

      response = articles.map do |article|
        {
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
          comments: article.comments,
          reading_time: article.reading_t,
          revision_history: article.revision_history
        }
      end

      render json: response
    end

    #Home page, with pagination
    def home
      bpp=params.fetch(:books_per_page, 3).to_i
      offset=params.fetch(:page, 0).to_i

      if(offset<1)
          offset=1
      end

      max_len=Article.all.count

      if(bpp>max_len)
          bpp=max_len
      end

      if(max_len==0)
          bpp=0
          offset=0
      else
          o_max=(max_len/bpp).to_i

          if(max_len.modulo(bpp)!=0)
              o_max=((max_len/bpp)+1).to_i
          end

          if(offset>o_max)
              offset=o_max
          end
      end

      articles = Article.includes(image_attachment: :blob).offset((offset-1)*bpp).limit(bpp)

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
            reading_time: article.reading_t,
            revision_history: article.revision_history
          }
      end
      render json: response
    end

    #sorting the articles
    def sort
        ordr = params.fetch(:order, :asc)

        # Performing the sorting based on 'created_at' in ascending or descending order
        articles = Article.order(created_at: ordr)

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
            reading_time: article.reading_t,
            revision_history: article.revision_history
          }
        end

        render json: response
    end

    #showing top posts, first on the basis of first likes and then comments.
    def top_posts
      all_articles = Article.all

      top_articles = all_articles.sort do |a, b|
        likes_comparison = b.no_of_likes <=> a.no_of_likes
        likes_comparison.zero? ? b.no_of_comments <=> a.no_of_comments : likes_comparison
      end

      response = top_articles.map do |article|
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
            reading_time: article.reading_t,
            revision_history: article.revision_history
          }
      end
      render json: response
    end

    def update_revision_history(article, revision_text)
      article.update(revision_history: "#{article.revision_history}#{revision_text}")
    end

    private

    def article_params
        params.permit(:title, :description, :genre, :image)
    end

    def article_search_params
        params.permit(:title, :author, :description, :genre)
    end
end
