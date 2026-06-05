module TicketsHelper
  # Render a number of hours without a trailing ".0" (e.g. 12.0 → "12", 4.5 → "4.5").
  def hours_label(value)
    n = value.to_f
    (n % 1).zero? ? n.to_i.to_s : n.round(1).to_s
  end
end
