class NotificationsController < ApplicationController
  def index
    @notifications = current_user.notifications.order(created_at: :desc).limit(50)
  end

  def mark_read
    notification = current_user.notifications.find(params[:id])
    notification.update(read_at: Time.current)
    redirect_back fallback_location: notifications_path
  end

  def mark_all_read
    current_user.notifications.where(read_at: nil).update_all(read_at: Time.current)
    redirect_to notifications_path, notice: "All notifications marked as read."
  end
end
