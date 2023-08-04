class ArticlesController < ApplicationController
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
        # render json: @articles.offset((@offset-1)*@bpp).limit(@bpp)
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

    def filter
      author_name = params.fetch(:author, "")
      title = params.fetch(:title, "")
      min_likes = params.fetch(:min_likes, nil) # The minimum number of likes
      max_likes = params.fetch(:max_likes, nil) # The maximum number of likes
      min_comments = params.fetch(:min_comments, nil) # The minimum number of comments
      max_comments = params.fetch(:max_comments, nil) # The maximum number of comments
    
      articles = Article.all
    
      if author_name.present?
        # Find the author by name (case-insensitive search)
        author = Author.find_by("lower(name) = ?", author_name.downcase)
    
        # If the author exists, filter articles by the author's ID
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
    
      # Build a JSON response with image URLs
      response = articles.map do |article|
        {
          id: article.id,
          title: article.title,
          author: article.author.name, # Use the author's name instead of the entire author object
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
        # Find the author by name (case-insensitive search)
        author = Author.find_by("lower(name) = ?", author_name.downcase)
    
        # If the author exists, filter articles by the author's ID
        articles = articles.where(author_id: author.id) if author
      end
    
      # Build a JSON response with image URLs
      response = articles.map do |article|
        {
          id: article.id,
          title: article.title,
          author: article.author.name, # Assuming 'author' is an association in the Article model
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
    
    
    

    def sort
        ordr = params.fetch(:order, :asc)
    
        # Perform the sorting based on 'created_at' in ascending or descending order
        articles = Article.order(created_at: ordr)
    
        # Build a JSON response with image URLs
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

    def create
         # Permit only the specific fields from the request parameters
        permitted_params = article_params

        # Find or create the author based on the author name
        author = Author.find_or_create_by(name: permitted_params[:author])

        # Create the article and associate it with the author
        article = Article.new(
            title: permitted_params[:title],
            description: permitted_params[:description],
            genre: permitted_params[:genre],
            author: author,
            no_of_likes: 0,
            no_of_comments: 0,
            likes: [],
            comments: []
        )

        # Attach the 'image' file to the article if present
        article.image.attach(permitted_params[:image]) if permitted_params[:image].present?

        if article.save
            # Update the article_ids of the associated author with the new article's ID
            author.update(article_ids: author.article_ids << article.id)

            # Build a JSON response with the image URL for the created article
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
            comments: article.comments
            }

            render json: response, status: :created
        else
            render json: { error: 'Failed to create the article' }, status: :unprocessable_entity
        end
    end

    def update
        article = Article.find_by(id: params[:id])
    
        unless article
          render json: { error: 'Article not found' }, status: :not_found
          return
        end
    
        # Permit only the specific fields from the request parameters
        permitted_params = article_params.except(:author)

        # Update the article with the permitted parameters
        if article.update(permitted_params)
            # Build a JSON response with the updated article details
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
            render json: { error: 'Failed to update the article' }, status: :unprocessable_entity
        end
    end   


    def delete
        article = Article.find_by(id: params[:id])
      
        if article
          # Get the associated author of the article
          author = article.author
      
          # Destroy the associated image along with the article
          article.image.purge if article.image.attached?
      
          # Destroy the article
          article.destroy
      
          # Remove the article's ID from the author's article_ids array
          author.update(article_ids: author.article_ids - [params[:id].to_i])
      
          render json: { message: 'Article deleted successfully!' }, status: :ok
        else
          render json: { error: 'Article not found' }, status: :not_found
        end
    end

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
            comments: article.comments
          }
      end
      render json: response
    end

    def show
      article = Article.find_by(id: params[:id])
  
      if article
        # Update the "views" count by 1
        article.increment!(:views)

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

    private

    def article_params
        # Permit only the specific fields from the request parameters
        params.permit(:title, :author, :description, :genre, :image)
    end

    def article_search_params
        # Permit only the 'description' field from the request parameters
        params.permit(:title, :author, :description, :genre)
    end
end
