# Gitea API integration service
class GiteaService
  BASE_URL = ENV.fetch("GITEA_URL", "http://localhost:3001")
  API_TOKEN = ENV.fetch("GITEA_TOKEN", "")

  def initialize
    @conn = Faraday.new(url: BASE_URL) do |f|
      f.request  :json
      f.response :json
      f.headers["Authorization"] = "token #{API_TOKEN}"
    end
  end

  # Create a branch for a ticket
  def create_branch(repo_owner:, repo_name:, branch_name:, base_branch: "main")
    response = @conn.post("/api/v1/repos/#{repo_owner}/#{repo_name}/branches") do |req|
      req.body = { new_branch_name: branch_name, old_branch_name: base_branch }
    end
    response.success? ? response.body : nil
  rescue Faraday::Error => e
    Rails.logger.error "GiteaService#create_branch failed: #{e.message}"
    nil
  end

  # Get pull requests for a repo
  def pull_requests(repo_owner:, repo_name:, state: "open")
    response = @conn.get("/api/v1/repos/#{repo_owner}/#{repo_name}/pulls", { state: state })
    response.success? ? response.body : []
  rescue Faraday::Error => e
    Rails.logger.error "GiteaService#pull_requests failed: #{e.message}"
    []
  end

  # Create or update a webhook
  def create_webhook(repo_owner:, repo_name:, target_url:, secret:)
    response = @conn.post("/api/v1/repos/#{repo_owner}/#{repo_name}/hooks") do |req|
      req.body = {
        active: true,
        config: { url: target_url, content_type: "json", secret: secret },
        events: %w[push pull_request issues],
        type: "gitea"
      }
    end
    response.success? ? response.body : nil
  rescue Faraday::Error
    nil
  end

  # Verify webhook HMAC signature
  def self.valid_signature?(payload, signature, secret)
    return false if signature.blank? || secret.blank?
    expected = "sha256=#{OpenSSL::HMAC.hexdigest('sha256', secret, payload)}"
    ActiveSupport::SecurityUtils.secure_compare(expected, signature)
  end
end
