module ApplicationHelper
  # Renders a circular avatar — Active Storage image or initials fallback.
  # size: pixel diameter (default 36)
  def user_avatar(user, size: 36, bg: "#4a90d9", css_class: "")
    shared_style = "width:#{size}px;height:#{size}px;border-radius:50%;flex-shrink:0;object-fit:cover;"

    if user&.avatar&.attached? && user.avatar.blob&.content_type&.start_with?("image/")
      if user.avatar.blob.content_type == "image/svg+xml"
        image_tag url_for(user.avatar),
                  style: "#{shared_style} display:block;",
                  class: css_class,
                  alt: user.display_name,
                  loading: "lazy"
      else
        image_tag user.avatar.variant(resize_to_fill: [ size * 2, size * 2 ]),
                  style: "#{shared_style} display:block;",
                  class: css_class,
                  alt: user.display_name,
                  loading: "lazy"
      end
    else
      initials = user ? user.initials : "?"
      content_tag(:div, initials,
        style: "#{shared_style} background:#{bg};color:#fff;display:flex;align-items:center;justify-content:center;font-weight:700;font-size:#{size * 0.38}px;",
        class: css_class,
        title: user&.display_name)
    end
  end

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
