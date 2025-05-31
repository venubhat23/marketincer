module Api
  module V1
    class InfluencerAnalyticsController < ApplicationController
      def show
        render json: {
          status: "success",
          data: {
            name: "Alice",
            username: "@name",
            followers: 32800,
            following: 30000,
            bio: "Lorem Ipsum dolor sit",
            category: "Beauty & Lifestyle",
            location: "USA",
            engagement_rate: "3.1%",
            earned_media: 249,
            average_interactions: "3.1%",
            campaign_analytics: {
              total_likes: 24300,
              total_comments: 403,
              total_engagement: "1.3%",
              total_reach: 32800
            },
            engagement_over_time: {
              period: "last_7_days",
              daily: {
                mon: 120,
                tue: 130,
                wed: 115,
                thu: 140,
                fri: 150,
                sat: 110,
                sun: 100
              }
            },
            audience_engagement: {
              likes: "60%",
              comments: "35%",
              shares: "5%"
            },
            audience_age: {
              "18-24": "40%",
              "24-30": "35%",
              ">30": "25%"
            },
            audience_reachability: {
              notable_followers_count: 132,
              notable_followers: [
                "Alice32.5K",
                "Sophia32.5K",
                "Allana32.5K",
                "Sam32.5K",
                "Julia32.5K"
              ]
            },
            audience_gender: {
              male: "45%",
              female: "55%"
            },
            audience_location: {
              countries: {
                "United States": 80,
                "India": 70,
                "Germany": 65,
                "Russia": 60,
                "Dubai": 55
              },
              cities: ["New York", "Mumbai", "Berlin", "Noida"]
            },
            audience_details: {
              languages: ["English", "Hindi"],
              interests: ["Music", "Food", "Lifestyle"],
              brand_affinity: ["Nike", "Sony", "Apple"]
            },
            recent_posts: [
              {
                platform: "Instagram",
                brand: "@anybrand",
                date: "2025-03-13",
                content: "Lorem ipsum dolor sit....",
                views: 37800,
                likes: 248,
                comments: 234,
                shares: 122,
                thumbnail_url: "https://cdn.example.com/post1.jpg"
              },
              {
                platform: "Instagram",
                brand: "@anybrand",
                date: "2025-03-13",
                content: "Lorem ipsum dolor sit....",
                views: 37800,
                likes: 248,
                comments: 234,
                shares: 122,
                thumbnail_url: "https://cdn.example.com/post2.jpg"
              }
            ]
          }
        }
      end
    end
  end
end
