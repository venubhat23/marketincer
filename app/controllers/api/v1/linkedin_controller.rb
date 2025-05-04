# app/controllers/api/v1/linkedin_controller.rb

module Api
  module V1
    class LinkedinController < ApplicationController
      def exchange_token
        code = params[:code]
        
        unless code.present?
          return render json: { error: "Missing required parameters" }, status: :bad_request
        end
        
        token_params = {
          grant_type: 'authorization_code',
          code: code,
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


            render json: { 
              access_token: response_body['access_token'],
              expires_in: response_body['expires_in']
            }
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
        
        begin
          uri = URI('https://api.linkedin.com/v2/me')
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          
          request = Net::HTTP::Get.new(uri)
          request['Authorization'] = "Bearer #{access_token}"
          request['Content-Type'] = 'application/json'
          
          response = http.request(request)
          response_body = JSON.parse(response.body)
          
          if response.code == '200'
            render json: response_body
          else
            render json: { error: "Failed to fetch profile", details: response_body }, status: :unprocessable_entity
          end
        rescue => e
          render json: { error: "Error fetching profile", details: e.message }, status: :internal_server_error
        end
      end
    end
  end
end
