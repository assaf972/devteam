class DockerContainersController < ApplicationController
  before_action :load_servers

  def index
    @selected_ip = params[:server].presence || @servers.first&.ip_address
    load_containers
  end

  def action
    ip        = params[:server].to_s
    container = params[:container].to_s
    verb      = params[:verb].to_s

    docker = Ops::DockerClient.new(server_ip: ip)
    msg    = docker.action(verb, container)
    redirect_to docker_containers_path(server: ip), notice: msg
  rescue Ops::DockerClient::Error => e
    redirect_to docker_containers_path(server: ip), alert: e.message
  end

  def logs
    ip        = params[:server].to_s
    container = params[:container].to_s
    docker    = Ops::DockerClient.new(server_ip: ip)
    @logs     = docker.container_logs(container)
    @container = container
    @server_ip = ip
    render layout: false
  rescue Ops::DockerClient::Error => e
    render plain: e.message, status: :unprocessable_entity, layout: false
  end

  private

  def load_servers
    @servers = ServerHeartbeat.servers.to_a
  end

  def load_containers
    return @containers = [] if @selected_ip.blank?
    docker      = Ops::DockerClient.new(server_ip: @selected_ip)
    @docker     = docker
    @containers = docker.containers
  rescue Ops::DockerClient::Error => e
    @containers = []
    flash.now[:alert] = e.message
  end
end
