# app/controllers/api/v1/purchase_orders_controller.rb
module Api
  module V1
    class PurchaseOrdersController < ApplicationController
      before_action :authenticate_user!

      # GET /api/v1/purchase_orders
      def index
        purchase_orders = @current_user.purchase_orders
        render json: purchase_orders, status: :ok
      end

      # GET /api/v1/purchase_orders/:id
      def show
        purchase_order = @current_user.purchase_orders.find_by(id: params[:id])

        if purchase_order
          render json: { purchase_order: purchase_order }, status: :ok
        else
          render json: { error: 'Purchase Order not found or not authorized' }, status: :not_found
        end
      end

      # POST /api/v1/purchase_orders
      def create
        purchase_order = @current_user.purchase_orders.build(purchase_order_params.except(:line_items))

        if params[:purchase_order][:line_items].present?
          permitted_line_items = params[:purchase_order][:line_items].map do |item|
            item.permit(:description, :quantity, :unit_price).to_h
          end
          purchase_order.line_items = permitted_line_items
        end

        if purchase_order.save
          render json: { message: 'Purchase Order created successfully', purchase_order: purchase_order }, status: :created
        else
          render json: { errors: purchase_order.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PUT /api/v1/purchase_orders/:id
      def update
        purchase_order = @current_user.purchase_orders.find_by(id: params[:id])

        if purchase_order.nil?
          return render json: { error: 'Purchase Order not found or not authorized' }, status: :not_found
        end

        purchase_order.assign_attributes(purchase_order_params.except(:line_items))

        if params[:purchase_order][:line_items].present?
          permitted_line_items = params[:purchase_order][:line_items].map do |item|
            item.permit(:description, :quantity, :unit_price).to_h
          end
          purchase_order.line_items = permitted_line_items
        end

        if purchase_order.save
          render json: { message: 'Purchase Order updated successfully', purchase_order: purchase_order }, status: :ok
        else
          render json: { errors: purchase_order.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/purchase_orders/:id
      def destroy
        purchase_order = @current_user.purchase_orders.find_by(id: params[:id])

        if purchase_order
          purchase_order.destroy
          render json: { message: 'Purchase Order deleted successfully' }, status: :ok
        else
          render json: { error: 'Purchase Order not found or not authorized' }, status: :not_found
        end
      end

      # GET /api/v1/purchase_orders/dashboard
      def dashboard
        purchase_orders = @current_user.purchase_orders

        total_amount = purchase_orders.sum(:total_amount)
        total_paid = purchase_orders.where(status: 'Paid').sum(:total_amount)
        total_pending = purchase_orders.where(status: 'Pending').sum(:total_amount)

        render json: {
          total_amount: total_amount,
          total_paid: total_paid,
          total_pending: total_pending,
          purchase_orders: purchase_orders
        }, status: :ok
      end

      private

      def purchase_order_params
        params.require(:purchase_order).permit(
          :company_name, :gst_number, :phone_number, :address, :customer,
          :company_website, :job_title, :work_email, :gst_percentage, 
          :status, :order_number, :customer,
          line_items: [:description, :quantity, :unit_price]
        )
      end
    end
  end
end
