class PaymentsController < ApplicationController
  before_action :authenticate_user, only: [:subscribe, :payment_callback, :payments_page]

  require "razorpay"

  #subscribing the user, this function will give order_id to frontend
  def subscribe
    subscription_plan = params[:subscription_plan]
    case subscription_plan
    when 'free'
      current_user.update(subscription_plan: 'free', remaining_posts: 1, expires_at: Time.now + 1.month)
      render json: { message: 'Subscription successful', user: current_user }, status: :ok

    when '3_posts', '5_posts', '10_posts'
      case subscription_plan
      when '3_posts'
        amount = 300
      when '5_posts'
        amount = 500
      when '10_posts'
        amount = 1000
      end

      order = Razorpay::Order.create(amount: amount, currency: 'INR')

      session[:razorpay_order_id] = order.id
      session[:subscription_plan] = subscription_plan
      session[:payment_amount] = amount

      render json: { order_id: order.id, amount: amount }, status: :ok
    else
      render json: { error: 'Invalid subscription plan' }, status: :unprocessable_entity
    end
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  #demo fun to check frontend.
  def payments_page
    render 'payments'
  end

  #frontend then will return razorpay_signature and razorpay_payment_id in params, by using them we can verify the payment.
  def payment_callback
    razorpay_signature = params[:razorpay_signature]
    payment_id = params[:razorpay_payment_id]
    order_id = session[:razorpay_order_id]
    amount = params[:amount].to_i

    payload = "#{order_id}|#{payment_id}"

    client = Razorpay::Client.new(secret_key: 's4ohOw8UuO35BAjheDlhvn9L')
    verified = client.utility.verify_payment_signature(payload, razorpay_signature)

    if verified && amount == params[:amount]
      subscription_plan = session[:subscription_plan]
      case subscription_plan
      when '3_posts'
        current_user.update(subscription_plan: '3_posts', remaining_posts: 3, expires_at: Time.now + 1.month)
      when '5_posts'
        current_user.update(subscription_plan: '5_posts', remaining_posts: 5, expires_at: Time.now + 1.month)
      when '10_posts'
        current_user.update(subscription_plan: '10_posts', remaining_posts: 10, expires_at: Time.now + 1.month)
      end

      render json: { message: 'Payment confirmed and subscription updated' }, status: :ok
    else
      render json: { error: 'Payment verification failed' }, status: :unprocessable_entity
    end
  end
end
