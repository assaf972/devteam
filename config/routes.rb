Rails.application.routes.draw do
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
    resources :documents, shallow: true
    resources :branches, only: [ :index, :show ], shallow: true
    resources :pull_requests, only: [ :index, :show ], shallow: true
    resources :meetings, shallow: true
    resources :project_memberships, only: %i[create destroy]
    resources :activities,           only: %i[index]
    member do
      get :report
      get :ci_dashboard
    end
  end

  resources :meetings do
    member do
      post :join
      post :end_meeting
      get  :ical
    end
  end

  resources :notifications, only: [ :index ] do
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
end
