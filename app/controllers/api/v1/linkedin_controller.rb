module Api
  module V1
    class LinkedinController < ApplicationController
      before_action :authenticate_user!

      def exchange_token
        code = params[:code]
        redirect_uri = params[:redirect_uri]

        unless code.present? && redirect_uri.present?
          return render json: { error: "Missing required parameters" }, status: :bad_request
        end

        token_params = {
          grant_type: 'authorization_code',
          code: code,
          redirect_uri: redirect_uri,
          client_id: '77ufne14jzxbbc',
          client_secret: 'WPL_AP1.Q1h1nSOAtOfOgsNL.9zPzwA=='
        }

        begin
          uri = URI('https://www.linkedin.com/oauth/v2/accessToken')
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true

          request = Net::HTTP::Post.new(uri)
          request.set_form_data(token_params)
          request['Content-Type'] = 'application/x-www-form-urlencoded'

          response = http.request(request)
          response_body = JSON.parse(response.body)

          if response.code == '200' && response_body['access_token']
            # Get user profile with the access token
            user_profile = fetch_user_profile(response_body['access_token'])

            if user_profile[:success]
              # --- Transform picture field here ---
              picture_url = user_profile[:data]["picture"]
              user_profile[:data]["picture"] = {
                "data" => {
                  "height" => 50,
                  "width" => 50,
                  "is_silhouette" => false,
                  "url" => picture_url
                }
              }

              # Connect LinkedIn page
              if @current_user.present?
                page_connector = LinkedinPageConnectorService.new(@current_user, {
                  access_token: response_body['access_token'],
                  user_info: user_profile[:data],
                  picture_url: picture_url
                })

                begin
                  social_page = page_connector.connect

                  render json: {
                    status: 'success',
                    message: 'Page connected successfully',
                    access_token: response_body['access_token'],
                    expires_in: response_body['expires_in'],
                    user_profile: user_profile[:data],
                    social_page: social_page
                  }
                rescue => e
                  render json: { error: "Failed to connect LinkedIn page", details: e.message }, status: :unprocessable_entity
                end
              else
                render json: {
                  access_token: response_body['access_token'],
                  expires_in: response_body['expires_in'],
                  user_profile: user_profile[:data]
                }
              end
            else
              render json: { error: "Failed to fetch user profile", details: user_profile[:error] }, status: :unprocessable_entity
            end
          else
            render json: { error: "Failed to exchange code for token", details: response_body }, status: :unprocessable_entity
          end
        rescue => e
          render json: { error: "Error exchanging code for token", details: e.message }, status: :internal_server_error
        end
      end


      def get_profile
        access_token = params[:access_token]
        
        unless access_token.present?
          return render json: { error: "Access token is required" }, status: :bad_request
        end
        
        user_profile = fetch_user_profile(access_token)
        
        if user_profile[:success]
          render json: user_profile[:data]
        else
          render json: { error: user_profile[:error][:message], details: user_profile[:error][:details] }, 
                 status: user_profile[:error][:status] || :unprocessable_entity
        end
      end
      
      def disconnect
        return render json: { error: "User not authenticated" }, status: :unauthorized unless current_user.present?
        
        page_params = {
          id: params[:id],
          social_account_id: params[:social_account_id]
        }
        
        page_connector = LinkedinPageConnectorService.new(current_user, page_params)
        result = page_connector.disconnect
        
        if result[:success]
          render json: { status: 'success', message: 'LinkedIn page disconnected successfully' }
        else
          render json: { error: result[:error] }, status: :unprocessable_entity
        end
      end

      private
      
      def fetch_user_profile(access_token)
        begin
          uri = URI('https://api.linkedin.com/v2/userinfo')
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          
          request = Net::HTTP::Get.new(uri)
          request['Authorization'] = "Bearer #{access_token}"
          request['Content-Type'] = 'application/json'
          
          response = http.request(request)
          response_body = JSON.parse(response.body)
          
          if response.code == '200'
            { success: true, data: response_body }
          else
            { 
              success: false, 
              error: { 
                message: "Failed to fetch LinkedIn profile", 
                details: response_body,
                status: response.code.to_i
              } 
            }
          end
        rescue => e
          { 
            success: false, 
            error: { 
              message: "Error fetching LinkedIn profile", 
              details: e.message,
              status: 500
            } 
          }
        end
      end
    end
  end
end