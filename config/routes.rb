Rails.application.routes.draw do
  # ── DevTeam CLI / VS Code Extension API ─────────────────────────────────
  namespace :api do
    namespace :v1 do
      get  "me",               to: "users#me"
      get  "token",            to: "users#token"
      post "token/regenerate", to: "users#regenerate_token"
      resources :tickets,  only: %i[index show create update]
      resources :pull_requests, only: %i[index show create]
      resources :ci_runs, only: %i[index show create] do
        resources :test_results, only: %i[index create], module: :ci_runs
      end
      resources :deployments, only: %i[index show create update]
      resources :projects, only: %i[index show]
      post "checkout", to: "checkout#create"
    end
  end

  # Top-level documents overview (across all projects)
  get "documents", to: "all_documents#index", as: :all_documents

  get "admin/users"
  get "admin/client_accounts"
  get "admin/settings"
  get "reports/ci_summary"
  get "reports/deployment_summary"
  get "reports/test_coverage"
  get "reports/sprint_velocity"
  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations"
  }

  # User profile (separate from Devise registrations)
  resource :profile, only: %i[edit update], controller: "profile"

  # ── Customer Portal ──────────────────────────────────────────────────────
  devise_for :customer_users,
             path: "portal",
             path_names: { sign_in: "login", sign_out: "logout" },
             controllers: { sessions: "customer_portal/sessions" },
             skip: %i[registrations confirmations unlocks]

  namespace :customer_portal, path: "portal" do
    root "dashboard#index"
    resources :tickets,    only: %i[index show new create]
    resources :messages,   only: %i[index create]
    resources :milestones, only: %i[index]
    resources :documents,  only: %i[index show]
  end
  # ─────────────────────────────────────────────────────────────────────────

  root "dashboard#index"
  get "dashboard", to: "dashboard#index", as: :dashboard
  get "today",     to: "today#index",     as: :today
  get "calendar",  to: "calendar#index",  as: :calendar
  get "calendar/events", to: "calendar#events", as: :calendar_events

  resources :customers do
    resources :customer_tickets do
      member do
        patch :resolve
        patch :link_ticket
      end
    end
    resources :installations
  end

  resources :projects do
    resources :tickets, shallow: true
    resources :sprints, shallow: true
    resources :milestones, shallow: true
    resources :ci_runs, only: [ :index, :show ], shallow: true
    resources :deployments, shallow: true
    resources :documents, shallow: true do
      collection { get :templates }
      member do
        post :save_as_template
        get  :new_from_template
      end
    end
    resources :branches, only: [ :index, :show ], shallow: true
    resources :pull_requests, only: [ :index, :show ], shallow: true do
      member { post :sync }
    end
    resources :project_memberships, only: %i[create destroy]
    resources :activities,           only: %i[index]
    member do
      get :report
      get :ci_dashboard
      get :calendar_events
    end
  end

  resources :meetings do
    member do
      post :join
      post :end_meeting
      get  :ical
      post :invite
      patch :save_recording
    end
    resources :comments, only: %i[create destroy], controller: "meeting_comments"
    collection { get :project_meetings, path: "project/:project_id" }
  end

  # project-scoped meeting index (e.g. linked from project page)
  get "projects/:project_id/meetings", to: "meetings#index", as: :project_meetings

  resources :notifications do
    collection { post :mark_all_read }
    member { patch :mark_read }
  end

  resources :chat_rooms, only: %i[index show new create] do
    resources :chat_messages, only: %i[create]
  end

  # Ticket comments — derived from ticket (project resolved via ticket.project)
  resources :tickets, only: [] do
    resources :comments, only: %i[create destroy]
  end

  # Sprint comments
  resources :sprints, only: [] do
    resources :comments, only: %i[create destroy], controller: "sprint_comments"
  end

  # Webhooks (no CSRF – verified by secret header)
  post "webhooks/gitea",      to: "webhooks#gitea"
  post "webhooks/jenkins",    to: "webhooks#jenkins"
  post "webhooks/exception",  to: "webhooks#exception"

  namespace :reports do
    get :ci_summary
    get :deployment_summary
    get :test_coverage
    get :sprint_velocity
  end

  namespace :admin do
    resources :users
    resources :client_accounts
    get :settings
    patch :settings, to: "admin#update_settings"
  end

  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest"       => "rails/pwa#manifest",       as: :pwa_manifest

  # ── Mobile UI ───────────────────────────────────────────────────────────────
  scope :mobile, as: :mobile do
    get "today",       to: "mobile#today",       as: :today
    get "messages",    to: "mobile#messages",    as: :messages
    get "meetings",    to: "mobile#meetings",    as: :meetings
    get "projects",    to: "mobile#projects",    as: :projects
    get "tickets",     to: "mobile#tickets",     as: :tickets
    get "video-calls", to: "mobile#video_calls", as: :video_calls
    root to: "mobile#today", as: :root
  end
end
