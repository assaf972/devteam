class NotificationsController < ApplicationController
  before_action :set_notification, only: [ :show, :edit, :update, :destroy, :mark_read ]

  def index
    @notifications = current_user.notifications
                                 .order(created_at: :desc)
                                 .limit(200)
  end

  def show; end

  def new
    @notification = current_user.notifications.build(type: "Notification")
  end

  def create
    @notification = current_user.notifications.build(notification_params)
    @notification.type = "Notification" if @notification.type.blank?

    if @notification.save
      redirect_to @notification, notice: "Notification created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @notification.update(notification_params)
      redirect_to @notification, notice: "Notification updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def mark_read
    @notification.update(read_at: Time.current)
    redirect_back fallback_location: notifications_path
  end

  def destroy
    @notification.destroy
    redirect_to notifications_path, notice: "Notification deleted successfully."
  end

  def mark_all_read
    current_user.notifications.where(read_at: nil).update_all(read_at: Time.current)
    redirect_to notifications_path, notice: "All notifications marked as read."
  end

  private

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end

  def notification_params
    params.require(:notification).permit(:message, :error_message, :backtrace, :read_at)
  end
end
