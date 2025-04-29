# app/controllers/api/v1/invoices_controller.rb
module Api
  module V1
    class InvoicesController < ApplicationController
      before_action :authenticate_user!

      # POST /api/v1/invoices
      def create
        invoice = @current_user.invoices.build(invoice_params)
        if invoice.save
          render json: { message: 'Invoice created successfully', invoice: invoice }, status: :created
        else
          render json: { errors: invoice.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PUT /api/v1/invoices/:id
      def update
        invoice = @current_user.invoices.find(params[:id])

        if invoice.update(invoice_params)
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

      # GET /api/v1/invoices/dashboard
      def dashboard
        # Fetch all invoices for the authenticated user
        invoices = @current_user.invoices

        # Separate invoices into paid and pending categories
        paid_invoices = invoices.where(status: 'paid')
        pending_invoices = invoices.where(status: 'pending')

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

      # Strong parameters for invoice creation and update
      def invoice_params
          params.require(:invoice).permit(
            :company_name,
            :gst_number,
            :phone_number,
            :address,
            :company_website,
            :job_title,
            :work_email,
            :gst_percentage,
            :total_amount,
            :status,
            :due_date,
            line_items: [:description, :quantity, :unit_price] # <<< this
          )

      end
    end
  end
end
