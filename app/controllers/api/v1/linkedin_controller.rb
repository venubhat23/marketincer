module Api
  module V1
    class LinkedinController < ApplicationController
      before_action :authenticate_user!

      def connect
        # Validate required parameters
        required_params = [:access_token, :user_info]
        missing_params = required_params.select { |param| params[param].blank? }
        
        if missing_params.any?
          return render json: { 
            error: "Missing required parameters: #{missing_params.join(', ')}" 
          }, status: :bad_request
        end

        begin
          # Prepare page parameters for the service
          page_params = {
            access_token: params[:access_token],
            user_info: params[:user_info],
            picture_url: params[:picture_url] # Optional parameter
          }

          # Use LinkedinPageConnectorService to connect the page
          page_connector = LinkedinPageConnectorService.new(current_user, page_params)
          social_page = page_connector.connect

          render json: {
            status: 'success',
            message: 'LinkedIn page connected successfully',
            social_page: {
              id: social_page.id,
              name: social_page.name,
              username: social_page.username,
              social_id: social_page.social_id,
              picture_url: social_page.picture_url,
              connected: social_page.connected,
              created_at: social_page.created_at
            }
          }

        rescue ActiveRecord::RecordInvalid => e
          render json: { 
            error: "Validation failed", 
            details: e.record.errors.full_messages 
          }, status: :unprocessable_entity

        rescue => e
          Rails.logger.error "LinkedIn connect error: #{e.message}"
          render json: { 
            error: "Failed to connect LinkedIn page", 
            details: e.message 
          }, status: :internal_server_error
        end
      end

    def exchange_token
      code = params[:code]
      redirect_uri = params[:redirect_uri]

      unless code.present? && redirect_uri.present?
        return render json: { error: "Missing required parameters" }, status: :bad_request
      end
      
      if params[:type] == "profile"
        token_params = {
          grant_type: 'authorization_code',
          code: code,
          redirect_uri: redirect_uri,
          client_id: '77ufne14jzxbbc',
          client_secret: 'WPL_AP1.Q1h1nSOAtOfOgsNL.9zPzwA=='
        }
      else
        token_params = {
          grant_type: 'authorization_code',
          code: code,
          redirect_uri: redirect_uri,
          client_id: '780iu7cgaok1lf',
          client_secret: 'WPL_AP1.pBnxoZgtOaxFkqeN.4Z42vA=='
        }
      end

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
          access_token = response_body['access_token']
          if params[:type] == "pages"
            # Step 1: Call organizationAcls to get all organization URNs
            org_uri = URI("https://api.linkedin.com/v2/organizationAcls?q=roleAssignee")
            org_http = Net::HTTP.new(org_uri.host, org_uri.port)
            org_http.use_ssl = true

            org_request = Net::HTTP::Get.new(org_uri)
            org_request['Authorization'] = "Bearer #{access_token}"
            org_request['Content-Type'] = 'application/json'
            org_response = org_http.request(org_request)
            org_data = JSON.parse(org_response.body)

            # Get all approved administrator organizations and extract unique org IDs
            approved_admin_orgs = org_data["elements"].select do |element|
              element["state"] == "APPROVED" && element["role"] == "ADMINISTRATOR"
            end

            unless approved_admin_orgs.any?
              return render json: { error: "No approved administrator organizations found" }, status: :unprocessable_entity
            end

            # Extract unique organization IDs to avoid duplicates
            unique_org_ids = approved_admin_orgs.map { |org| org["organization"].split(":").last }.uniq
              puts "Organization IDS: #{unique_org_ids}"

            # Step 2: Fetch details for all organizations
            organizations = []
            
            unique_org_ids.each do |organization_id|

              org_details_uri = URI("https://api.linkedin.com/v2/organizations/#{organization_id}")
              org_details_http = Net::HTTP.new(org_details_uri.host, org_details_uri.port)
              org_details_http.use_ssl = true
              org_details_request = Net::HTTP::Get.new(org_details_uri)
              org_details_request['Authorization'] = "Bearer #{access_token}"
              org_details_request['Content-Type'] = 'application/json'

              org_details_response = org_details_http.request(org_details_request)

              puts "Organization ID: #{organization_id}"
              puts "Response Code: #{org_details_response.code}"
              puts "Response Body: #{org_details_response.body}"


              if org_details_response.code == '200'
                org_details_data = JSON.parse(org_details_response.body)
                organizations << org_details_data
              else
                # Log error but continue with other organizations
                Rails.logger.error "Failed to fetch organization #{organization_id}: #{org_details_response.body}"
              end
            end

            if organizations.empty?
              return render json: { error: "Failed to fetch any organization details" }, status: :unprocessable_entity
            end

            # Transform organizations data to match the desired format
            accounts = organizations.map do |org|
              {
                name: org["localizedName"] || org["name"]["localized"]["en_US"],
                username: org["vanityName"],
                type: "linkedin_page",
                social_id: org["id"].to_s,
                page_id: org["id"].to_s,
                access_token: access_token,
                user: org # Store the entire organization info under user
              }
            end

            return render json: {
              data: {
                accounts: accounts
              },
              status: "complete",
              long_poll: true
            }
          else
            user_profile = fetch_user_profile(access_token)

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
                  access_token: access_token,
                  user_info: user_profile[:data],
                  picture_url: picture_url
                })

                begin
                  social_page = page_connector.connect

                  render json: {
                    status: 'success',
                    message: 'Page connected successfully',
                    access_token: access_token,
                    expires_in: response_body['expires_in'],
                    user_profile: user_profile[:data],
                    social_page: social_page
                  }
                rescue => e
                  render json: { error: "Failed to connect LinkedIn page", details: e.message }, status: :unprocessable_entity
                end
              else
                render json: {
                  access_token: access_token,
                  expires_in: response_body['expires_in'],
                  user_profile: user_profile[:data]
                }
              end
            else
              render json: { error: "Failed to fetch user profile", details: user_profile[:error] }, status: :unprocessable_entity
            end
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