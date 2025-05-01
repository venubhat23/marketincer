# app/controllers/api/v1/invoices_controller.rb
module Api
  module V1
    class InvoicesController < ApplicationController
      before_action :authenticate_user!

      # POST /api/v1/invoices
      def create
        # Start by building an invoice with permitted basic parameters
        invoice = @current_user.invoices.build(basic_params)
        
        # Handle line_items explicitly - convert to an array of hashes
        if params[:invoice][:line_items].present?
            # Permit the line items parameters before converting to hashes
            permitted_line_items = params[:invoice][:line_items].map do |line_item|
              line_item.permit(:description, :quantity, :unit_price).to_h
            end
            
            invoice.line_items = permitted_line_items
        end
        if invoice.save
          render json: { message: 'Invoice created successfully', invoice: invoice }, status: :created
        else
          render json: { errors: invoice.errors.full_messages }, status: :unprocessable_entity
        end

      end

      # PUT /api/v1/invoices/:id
      def update
        invoice = @current_user.invoices.find(params[:id])

        # Update basic attributes
        invoice.assign_attributes(basic_params)

        # Update line_items if provided
        if params[:invoice][:line_items].present?
          permitted_line_items = params[:invoice][:line_items].map do |line_item|
            line_item.permit(:description, :quantity, :unit_price).to_h
          end
          invoice.line_items = permitted_line_items
        end

        if invoice.save
          render json: { message: 'Invoice updated successfully', invoice: invoice }, status: :ok
        else
          render json: { errors: invoice.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PUT /api/v1/invoices/:id/update_status
      def update_status
        invoice = @current_user.invoices.find(params[:id])

        if invoice.update(status: params[:status])
          render json: { message: 'Invoice status updated', invoice: invoice }, status: :ok
        else
          render json: { errors: invoice.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/invoices/:id
      def destroy
        invoice = @current_user.invoices.find_by(id: params[:id])

        if invoice
          invoice.destroy
          render json: { message: 'Invoice deleted successfully' }, status: :ok
        else
          render json: { error: 'Invoice not found or not authorized' }, status: :not_found
        end
      end

      # GET /api/v1/invoices/:id
      def show
        invoice = @current_user.invoices.find_by(id: params[:id])

        if invoice
          render json: { invoice: invoice }, status: :ok
        else
          render json: { error: 'Invoice not found or not authorized' }, status: :not_found
        end
      end

      # GET /api/v1/invoices/dashboard
      def dashboard
        # Fetch all invoices for the authenticated user
        invoices = @current_user.invoices

        # Separate invoices into paid and pending categories
        paid_invoices = invoices.where(status: ['Paid', 'paid'])
        pending_invoices = invoices.where(status: ['Pending', 'pending'])

        # Calculate totals
        total_paid = paid_invoices.sum(:total_amount)
        total_pending = pending_invoices.sum(:total_amount)
        total_all = total_paid + total_pending

        # Merge paid and pending invoices and sort by created_at DESC
        all_invoices = (paid_invoices + pending_invoices).sort_by(&:created_at).reverse

        # Respond with the statistics
        render json: {
          paid_invoices_count: paid_invoices.count,
          pending_invoices_count: pending_invoices.count,
          total_paid: total_paid,
          total_pending: total_pending,
          total_all: total_all,
          all_invoices: all_invoices # Merged and sorted invoices
        }, status: :ok
      end

      private

      # Strong parameters for basic invoice attributes (without line_items)
      def basic_params
        params.require(:invoice).permit(
          :company_name,
          :customer,
          :gst_number,
          :phone_number,
          :address,
          :company_website,
          :job_title,
          :work_email,
          :gst_percentage,
          :total_amount,
          :status,
          :due_date
        )
      end
    end
  end
end