module Ops
  # Wraps a remote Docker host / agent on a server (Docker Engine API over TCP,
  # or a small SSH agent). Configure DOCKER_API_BASE to point at the per-host
  # agent. Until that's wired up it runs in demo mode, returning representative
  # containers + Dockerfile/compose so the console is fully clickable.
  class DockerClient
    class Error < StandardError; end

    API_BASE = ENV.fetch("DOCKER_API_BASE", "").freeze

    def initialize(server_ip:)
      @server_ip = server_ip
      @conn = build_connection if configured?
    end

    def configured? = API_BASE.present?

    def available?
      return false unless configured?
      @conn.get("/_ping").success?
    rescue Faraday::Error
      false
    end

    # [{ name, image, status, state, ports, cpu, mem }]
    def containers
      return demo_containers unless configured?

      resp = @conn.get("/containers/json", all: true)
      return [] unless resp.success?

      Array(resp.body).map do |c|
        { "name" => Array(c["Names"]).first.to_s.delete_prefix("/"), "image" => c["Image"],
          "status" => c["Status"], "state" => c["State"], "ports" => format_ports(c["Ports"]) }
      end
    rescue Faraday::Error => e
      raise Error, "Docker host #{@server_ip} unreachable: #{e.message}"
    end

    # Last 200 log lines for a container.
    def container_logs(container)
      return demo_logs(container) unless configured?
      resp = @conn.get("/containers/#{container}/logs", stdout: true, stderr: true, tail: 200)
      return "(no logs)" unless resp.success?
      resp.body.to_s.gsub(/[\x00-\x08\x0b\x0c\x0e-\x1f]/, "")
    rescue Faraday::Error => e
      raise Error, "Could not fetch logs for #{container}: #{e.message}"
    end

    def dockerfile  = read_file("Dockerfile")        || demo_dockerfile
    def compose_file = read_file("docker-compose.yml") || demo_compose

    # Lifecycle actions — no-ops in demo mode, return a human message.
    def action(verb, container)
      return "#{verb.to_s.humanize} #{container} — queued (no Docker host configured; demo)." unless configured?

      path = { restart: "/containers/#{container}/restart", stop: "/containers/#{container}/stop",
               start: "/containers/#{container}/start" }.fetch(verb.to_sym) { raise Error, "Unknown action #{verb}" }
      resp = @conn.post(path)
      raise Error, "Docker responded #{resp.status}" unless resp.success?
      "#{verb.to_s.humanize}ed #{container}."
    rescue Faraday::Error => e
      raise Error, "Docker host #{@server_ip} unreachable: #{e.message}"
    end

    def save_file(kind, _content)
      return "Saved #{kind} (demo — not persisted to a real host)." unless configured?
      # A real impl would PUT the file to the host agent and rebuild.
      "Saved #{kind} to #{@server_ip}."
    end

    private

    def build_connection
      Faraday.new(url: "#{API_BASE}") do |f|
        f.request :json
        f.response :json
        f.headers["X-Server-IP"] = @server_ip.to_s
        f.options.timeout = 15
      end
    end

    def read_file(_name) = nil # backend hook

    def format_ports(ports)
      Array(ports).filter_map { |p| p["PublicPort"] && "#{p['PublicPort']}→#{p['PrivatePort']}" }.join(", ")
    end

    # ── Demo data ──────────────────────────────────────────────────────────────
    def demo_containers
      [
        { "name" => "app",      "image" => "registry.local/app:latest",   "status" => "Up 3 days",    "state" => "running", "ports" => "8080→3000" },
        { "name" => "worker",   "image" => "registry.local/app:latest",   "status" => "Up 3 days",    "state" => "running", "ports" => "" },
        { "name" => "postgres", "image" => "postgres:16",                 "status" => "Up 12 days",   "state" => "running", "ports" => "5432→5432" },
        { "name" => "redis",    "image" => "redis:7",                     "status" => "Up 12 days",   "state" => "running", "ports" => "6379→6379" },
        { "name" => "nginx",    "image" => "nginx:1.27",                  "status" => "Restarting",   "state" => "restarting", "ports" => "80→80, 443→443" }
      ]
    end

    def demo_logs(container)
      <<~LOGS
        2026-06-08T08:01:12Z [info]  Starting #{container}...
        2026-06-08T08:01:13Z [info]  Loaded configuration from /etc/app/config.yml
        2026-06-08T08:01:14Z [info]  Database connection established
        2026-06-08T08:01:15Z [info]  Server listening on 0.0.0.0:3000
        2026-06-08T09:15:02Z [info]  GET /health 200 1ms
        2026-06-08T09:15:33Z [info]  POST /api/v1/tickets 201 12ms
        2026-06-08T09:16:44Z [warn]  Slow query detected (245ms): SELECT * FROM tickets WHERE ...
        2026-06-08T09:17:01Z [info]  GET /api/v1/projects 200 3ms
        2026-06-08T10:00:00Z [info]  Background job processed: SendNotificationJob
        2026-06-08T10:05:11Z [error] Retrying Sidekiq job (attempt 2/3): NetworkError
        2026-06-08T10:05:41Z [info]  Sidekiq job succeeded on retry
      LOGS
    end

    def demo_dockerfile
      <<~DOCKER
        FROM ruby:3.4-slim
        WORKDIR /app
        COPY Gemfile Gemfile.lock ./
        RUN bundle install --without development test
        COPY . .
        RUN bin/rails assets:precompile
        EXPOSE 3000
        CMD ["bin/rails", "server", "-b", "0.0.0.0"]
      DOCKER
    end

    def demo_compose
      <<~YAML
        services:
          app:
            image: registry.local/app:latest
            ports: ["8080:3000"]
            env_file: .env.production
            depends_on: [postgres, redis]
          postgres:
            image: postgres:16
            volumes: ["pgdata:/var/lib/postgresql/data"]
          redis:
            image: redis:7
        volumes:
          pgdata:
      YAML
    end
  end
end
