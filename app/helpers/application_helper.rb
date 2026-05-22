module ApplicationHelper
  def flash_class(type)
    {
      "notice"  => "alert-success",
      "success" => "alert-success",
      "alert"   => "alert-danger",
      "error"   => "alert-danger",
      "warning" => "alert-warning",
      "info"    => "alert-info"
    }.fetch(type.to_s, "alert-info")
  end

  def status_tag(status)
    color = case status.to_s
    when "passed", "done", "succeeded", "merged" then "bg-success"
    when "failed", "blocked", "error"             then "bg-danger"
    when "running", "in_progress", "open"         then "bg-warning text-dark"
    when "cancelled", "closed", "rolled_back"     then "bg-secondary"
    when "pending"                                 then "bg-info text-dark"
    else "bg-secondary"
    end
    content_tag(:span, status.to_s.humanize, class: "badge #{color}")
  end

  def priority_tag(priority)
    color = case priority.to_s
    when "critical" then "bg-danger"
    when "high"     then "bg-warning text-dark"
    when "medium"   then "bg-info text-dark"
    else "bg-secondary"
    end
    content_tag(:span, t("tickets.priorities.#{priority}"), class: "badge #{color}")
  end

  def rtl?
    I18n.locale.to_s == "he"
  end

  def jitsi_url_for(room_name)
    base = ENV.fetch("JITSI_URL", "https://meet.jit.si")
    "#{base}/#{ERB::Util.url_encode(room_name)}"
  end
end
