class MarketplaceService
  class << self
    # Get marketplace statistics for a brand
    def brand_statistics(user)
      return {} unless user.role.in?(['admin', 'brand'])

      posts = user.marketplace_posts
      
      {
        total_posts: posts.count,
        published_posts: posts.published.count,
        draft_posts: posts.draft.count,
        total_views: posts.sum(:views_count),
        total_bids: posts.joins(:bids).count,
        pending_bids: posts.joins(:bids).where(bids: { status: 'pending' }).count,
        accepted_bids: posts.joins(:bids).where(bids: { status: 'accepted' }).count,
        rejected_bids: posts.joins(:bids).where(bids: { status: 'rejected' }).count,
        avg_bids_per_post: posts.count > 0 ? (posts.joins(:bids).count.to_f / posts.count).round(2) : 0
      }
    end

    # Get marketplace statistics for an influencer
    def influencer_statistics(user)
      return {} unless user.role == 'influencer'

      bids = user.bids
      
      {
        total_bids: bids.count,
        pending_bids: bids.pending.count,
        accepted_bids: bids.accepted.count,
        rejected_bids: bids.rejected.count,
        total_bid_amount: bids.sum(:amount),
        avg_bid_amount: bids.count > 0 ? (bids.sum(:amount) / bids.count).round(2) : 0,
        success_rate: bids.count > 0 ? ((bids.accepted.count.to_f / bids.count) * 100).round(2) : 0
      }
    end

    # Get trending categories
    def trending_categories(limit = 5)
      MarketplacePost.published
                    .group(:category)
                    .order('COUNT(*) DESC')
                    .limit(limit)
                    .count
    end

    # Get popular target audiences
    def popular_target_audiences(limit = 5)
      MarketplacePost.published
                    .group(:target_audience)
                    .order('COUNT(*) DESC')
                    .limit(limit)
                    .count
    end

    # Search marketplace posts
    def search_posts(query, filters = {})
      posts = MarketplacePost.published.includes(:user, :bids)

      # Text search
      if query.present?
        posts = posts.where(
          "title ILIKE ? OR description ILIKE ? OR tags ILIKE ? OR brand_name ILIKE ?", 
          "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%"
        )
      end

      # Apply filters
      posts = posts.by_category(filters[:category]) if filters[:category].present?
      posts = posts.by_target_audience(filters[:target_audience]) if filters[:target_audience].present?
      
      if filters[:budget_min].present?
        posts = posts.where('budget >= ?', filters[:budget_min])
      end
      
      if filters[:budget_max].present?
        posts = posts.where('budget <= ?', filters[:budget_max])
      end
      
      if filters[:deadline_from].present?
        posts = posts.where('deadline >= ?', filters[:deadline_from])
      end
      
      if filters[:deadline_to].present?
        posts = posts.where('deadline <= ?', filters[:deadline_to])
      end

      if filters[:location].present?
        posts = posts.where('location ILIKE ?', "%#{filters[:location]}%")
      end

      if filters[:platform].present?
        posts = posts.where('platform ILIKE ?', "%#{filters[:platform]}%")
      end

      posts.recent
    end

    # Validate marketplace post data
    def validate_post_data(params)
      errors = []
      
      errors << "Title is required" if params[:title].blank?
      errors << "Description is required" if params[:description].blank?
      errors << "Budget must be greater than 0" if params[:budget].to_f <= 0
      errors << "Deadline is required" if params[:deadline].blank?
      errors << "Category must be A or B" unless params[:category].in?(['A', 'B'])
      errors << "Target audience is invalid" unless params[:target_audience].in?(['18–24', '24–30', '30–35', 'More than 35'])
      
      if params[:deadline].present?
        begin
          deadline = Date.parse(params[:deadline].to_s)
          errors << "Deadline must be in the future" if deadline <= Date.current
        rescue ArgumentError
          errors << "Invalid deadline format"
        end
      end

      errors
    end

    # Get recommended posts for an influencer
    def recommended_posts(user, limit = 10)
      return MarketplacePost.none unless user.role == 'influencer'

      # Get posts that the user hasn't bid on yet
      posts = MarketplacePost.published
                            .where.not(id: user.bids.select(:marketplace_post_id))
                            .includes(:user, :bids)
                            .recent
                            .limit(limit)

      posts
    end

    # Get marketplace insights
    def marketplace_insights
      {
        total_posts: MarketplacePost.published.count,
        total_bids: Bid.count,
        active_brands: User.joins(:marketplace_posts).where(marketplace_posts: { status: 'published' }).distinct.count,
        active_influencers: User.joins(:bids).distinct.count,
        avg_bids_per_post: MarketplacePost.published.count > 0 ? (Bid.count.to_f / MarketplacePost.published.count).round(2) : 0,
        categories: trending_categories,
        target_audiences: popular_target_audiences
      }
    end
  end
end