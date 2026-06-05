# Remote-machine (server) monitoring. A server is a distinct ip_address seen in
# the heartbeat stream. The index lists every server with its current OS status;
# show drills into current + historical CPU / memory / disk and recent errors.
class ServersController < ApplicationController
  def index
    @servers = ServerHeartbeat.servers.to_a
  end

  def show
    @ip = params[:ip].to_s
    @latest = ServerHeartbeat.for_ip(@ip).recent.first
    return redirect_to(servers_path, alert: "Unknown server.") unless @latest

    window     = (params[:hours].presence || 24).to_i.clamp(1, 720)
    @history   = ServerHeartbeat.for_ip(@ip).since(window.hours.ago).order(:recorded_at).to_a
    @window    = window

    # Chartkick series keyed by time label.
    @cpu_series  = series(@history, :cpu)
    @mem_series  = series(@history, :mem)
    @disk_series = series(@history, :disk)

    @deployments = Deployment.where(ip_address: @ip).includes(:project).order(created_at: :desc).limit(20)
  end

  private

  def series(history, attr)
    history.to_h { |h| [ h.recorded_at.strftime("%d %b %H:%M"), h.public_send(attr) ] }
  end
end
