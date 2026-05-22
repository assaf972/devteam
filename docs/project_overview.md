# DevTeam Hub — Project Documentation

> **Version:** 1.0  
> **Last updated:** May 22, 2026  
> **Stack:** Ruby on Rails 8.1.3 · SQLite3 · Bulma CSS · Stimulus JS · Solid Queue

---

## 1. What Is DevTeam Hub?

DevTeam Hub is an internal developer-team management dashboard built with Ruby on Rails 8. It centralises every aspect of a software-development team's day-to-day work into a single web application:

- **Project & Sprint tracking** — manage projects, iterations, and milestones
- **Ticket (issue) management** — Kanban-style work items with CI status badges
- **Customer support** — customer accounts, support tickets, and software installation records
- **CI/CD integration** — real-time Jenkins build results and Gitea repository events via webhooks
- **Deployment tracking** — web, Windows installer, Windows service, and Docker deploys
- **Meeting management** — schedule and join Jitsi video meetings from within the app
- **Documentation** — project-scoped knowledge base with Markdown rendering
- **Notifications** — in-app and email notifications for ticket assignments and CI failures
- **Internationalisation** — full English and Hebrew (RTL) support
- **Today Page** — personalised landing page for each developer showing their day at a glance

The application targets small-to-medium software teams (5–30 developers) who want an on-premise, self-hosted alternative to Jira + Confluence + Freshdesk combined.

---

## 2. Technology Stack

| Layer | Technology |
|---|---|
| Framework | Ruby on Rails 8.1.3 |
| Language | Ruby 3.4.5 |
| Database | SQLite3 (~> 2.0) |
| Web server | Puma |
| Background jobs | Solid Queue |
| Cache | Solid Cache |
| WebSockets | Solid Cable |
| Frontend CSS | Bulma (via cssbundling-rails) |
| Frontend JS | Stimulus + Turbo (Hotwire) |
| Asset pipeline | Propshaft + jsbundling-rails |
| Authentication | Devise |
| Authorisation | Pundit |
| HTTP client | Faraday |
| Pagination | Kaminari |
| Charts | Chartkick + Groupdate |
| Search | Ransack |
| Notifications | Noticed ~> 2.0 |
| Error tracking | Sentry (sentry-ruby + sentry-rails) |
| Markdown | Redcarpet |
| Calendar export | iCalendar |
| Tagging | acts-as-taggable-on |
| PDF generation | Prawn + prawn-table |
| File uploads | Active Storage (local disk) |
| Testing (unit) | RSpec + FactoryBot + Shoulda-matchers + Faker |
| Testing (BDD) | Cucumber-rails + Capybara |
| Deployment tooling | Kamal + Thruster |

---

## 3. Application Architecture

```
┌─────────────────────────────────────────────────┐
│                  Browser / PWA                  │
│         Turbo frames + Stimulus JS              │
└─────────────┬───────────────────────────────────┘
              │ HTTP / WebSocket
┌─────────────▼───────────────────────────────────┐
│              Puma (Rails 8 app)                 │
│  ┌─────────┐ ┌──────────────┐ ┌──────────────┐ │
│  │ Routes  │ │  Controllers │ │    Views     │ │
│  └────┬────┘ └──────┬───────┘ └──────┬───────┘ │
│       │             │                │          │
│  ┌────▼─────────────▼────────────────▼───────┐  │
│  │              Active Record Models         │  │
│  └────────────────────┬──────────────────────┘  │
│                       │                         │
│          ┌────────────▼──────────┐              │
│          │     SQLite3 DB        │              │
│          └───────────────────────┘              │
│                                                 │
│  ┌──────────────────────────────────────────┐   │
│  │  Solid Queue (background jobs)           │   │
│  │  · TicketMailer jobs                     │   │
│  │  · Notification dispatch                 │   │
│  │  · Gitea branch creation                 │   │
│  └──────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
              │                   │
     ┌────────▼───┐      ┌────────▼───────┐
     │  Jenkins   │      │   Gitea server │
     │  (webhooks)│      │  (webhooks)    │
     └────────────┘      └────────────────┘
```

**Key design choices:**

- Shallow-nested routes keep URLs short while maintaining resource context
- Polymorphic `comments` and `notifications` reduce table count
- `serialize :params, coder: JSON` on `Notification#params` since SQLite has no native JSON column
- Enum integers stored in DB for efficiency; all enums have named scopes

---

## 4. Database Tables & Models

### 4.1 `users`

The application's team members. Managed by Devise.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | integer | PK | |
| email | string | NOT NULL, unique | Devise |
| encrypted_password | string | NOT NULL | Devise |
| name | string | NOT NULL | display name |
| role | integer | | enum: developer(0) team_lead(1) project_manager(2) admin(3) qa(4) |
| preferred_language | string | | enum: "en" / "he" |
| reset_password_token | string | unique | Devise |
| remember_created_at | datetime | | Devise |
| created_at / updated_at | datetime | NOT NULL | |

**Associations:**

- `has_many :assigned_tickets` (FK: assignee_id on tickets)
- `has_many :triggered_ci_runs` (FK: triggered_by_id on ci_runs)
- `has_many :deployments` (FK: deployed_by_id)
- `has_many :authored_documents` (FK: author_id)
- `has_many :organized_meetings` (FK: organizer_id)
- `has_many :meetings, through: :meeting_attendees`
- `has_many :watched_tickets, through: :ticket_watchers`
- `has_many :notifications, polymorphic recipient`
- `has_many :assigned_customer_tickets` (FK: assigned_to_id)

**Validations:** name presence; email presence + uniqueness (delegated to Devise)

---

### 4.2 `projects`

Top-level container for all team work.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | integer | PK | |
| name | string | NOT NULL | |
| description | text | | |
| tech_stack | string | | |
| repo_url | string | | URL to Gitea repository |
| gitea_repo_id | string | | Gitea internal repo identifier |
| active | boolean | DEFAULT true | soft-delete flag |
| created_at / updated_at | datetime | NOT NULL | |

**Associations:** has_many sprints, milestones, tickets, ci_runs, deployments, documents, meetings, pull_requests, branches, installations

**Validations:** name presence

**Scopes:** `.active` → `where(active: true)`

---

### 4.3 `tickets`

Core work-item / issue entity.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | integer | PK | |
| project_id | bigint | NOT NULL, FK | |
| sprint_id | bigint | FK | optional |
| assignee_id | bigint | FK → users | optional |
| milestone_id | integer | FK | optional |
| title | string | | |
| description | text | | |
| status | integer | | enum below |
| priority | integer | DEFAULT medium | enum below |
| story_points | integer | | |
| branch_name | string | | linked Git branch |
| pr_number | integer | | linked PR number |
| latest_ci_run_id | integer | | denormalised FK |
| created_at / updated_at | datetime | NOT NULL | |

**Status enum:** `backlog(0)` `open(1)` `in_progress(2)` `in_review(3)` `testing(4)` `done(5)` `closed(6)` `blocked(7)`

**Priority enum:** `low(0)` `medium(1)` `high(2)` `critical(3)`

**Associations:** belongs_to project, sprint (optional), assignee/User (optional), milestone (optional); has_many comments (polymorphic), branches, pull_requests, ci_runs, ticket_watchers, test_results (through ci_runs)

**Validations:** title presence, project presence

**Tagging:** `acts_as_taggable_on :tags, :labels`

---

### 4.4 `sprints`

Iteration containers for tickets.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | integer | PK | |
| project_id | bigint | NOT NULL, FK | |
| name | string | NOT NULL | |
| status | integer | DEFAULT planning | enum below |
| start_date | date | NOT NULL | |
| end_date | date | NOT NULL | |
| goal | text | | sprint goal description |
| created_at / updated_at | datetime | NOT NULL | |

**Status enum:** `planning(0)` `active(1)` `completed(2)` `cancelled(3)`

**Scopes:** `.active`, `.current` (active within today's date range)

---

### 4.5 `milestones`

Release gates linked to projects and tickets.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | integer | PK | |
| project_id | bigint | NOT NULL, FK | |
| name | string | | |
| description | text | | |
| due_date | date | | |
| status | integer | | enum: open(0) in_progress(1) completed(2) |
| created_at / updated_at | datetime | NOT NULL | |

**Associations:** belongs_to project; has_many tickets

---

### 4.6 `ci_runs`

Records of Jenkins (or other CI) builds.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | integer | PK | |
| project_id | bigint | NOT NULL, FK | |
| ticket_id | bigint | FK | optional |
| triggered_by_id | bigint | FK → users | optional |
| build_number | string | NOT NULL | |
| branch_name | string | | |
| commit_sha | string | | |
| status | integer | DEFAULT pending | enum below |
| log_url | string | | link to Jenkins build log |
| started_at | datetime | | |
| finished_at | datetime | | |
| created_at / updated_at | datetime | NOT NULL | |

**Status enum:** `pending(0)` `running(1)` `passed(2)` `failed(3)` `cancelled(4)` `error(5)`

**Methods:** `#duration` → minutes between started_at and finished_at

---

### 4.7 `test_results`

Individual test case outcomes belonging to a CI run.

| Column | Type | Notes |
|---|---|---|
| ci_run_id | bigint | FK |
| name | string | test name |
| passed | boolean | |
| duration_ms | integer | |
| failure_message | text | |

---

### 4.8 `deployments`

Deployment events (web, installer, service, Docker).

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | integer | PK | |
| project_id | bigint | NOT NULL, FK | |
| deployed_by_id | bigint | FK → users | |
| client_account_id | bigint | FK | optional |
| version | string | NOT NULL | |
| environment | string | NOT NULL | production/staging/uat/etc. |
| status | integer | DEFAULT pending | enum below |
| deploy_type | integer | DEFAULT web_app | enum below |
| deployed_at | datetime | | |
| machine_name | string | | target host |
| notes | text | | |
| created_at / updated_at | datetime | NOT NULL | |

**Status enum:** `pending(0)` `in_progress(1)` `succeeded(2)` `failed(3)` `rolled_back(4)`

**Deploy type enum:** `web_app(0)` `windows_installer(1)` `windows_service(2)` `docker(3)`

**Associations:** belongs_to project, deployed_by/User (optional), client_account (optional); has_many installations

---

### 4.9 `documents`

Project knowledge-base articles with Markdown content.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | integer | PK | |
| project_id | bigint | NOT NULL, FK | |
| author_id | bigint | FK → users | optional |
| title | string | NOT NULL | |
| content | text | NOT NULL | Markdown |
| summary | text | | |
| doc_type | integer | DEFAULT other | enum below |
| version_number | string | | e.g. "1.2" |
| created_at / updated_at | datetime | NOT NULL | |

**Doc type enum:** `spec(0)` `risk_management(1)` `user_story(2)` `timeline(3)` `test_coverage(4)` `architecture(5)` `runbook(6)` `other(7)`

**Features:** Active Storage attachment, polymorphic comments, `acts_as_taggable_on :tags`

---

### 4.10 `meetings`

Scheduled team meetings with optional Jitsi video link.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | integer | PK | |
| project_id | bigint | FK | optional |
| organizer_id | bigint | FK → users | optional |
| title | string | NOT NULL | |
| description | text | | |
| agenda | text | | |
| meeting_type | integer | DEFAULT other | enum below |
| status | integer | DEFAULT scheduled | enum below |
| scheduled_at | datetime | NOT NULL | |
| duration_minutes | integer | | |
| jitsi_room | string | | room name on Jitsi server |
| recording_url | string | | link to recording |
| notes | text | | post-meeting notes |
| created_at / updated_at | datetime | NOT NULL | |

**Meeting type enum:** `daily_standup(0)` `sprint_planning(1)` `sprint_review(2)` `retrospective(3)` `demo(4)` `one_on_one(5)` `other(6)`

**Status enum:** `scheduled(0)` `in_progress(1)` `completed(2)` `cancelled(3)`

**Methods:** `#jitsi_url(base_url)` builds full Jitsi room URL

---

### 4.11 `meeting_attendees`

Join table between meetings and users.

| Column | Type | Notes |
|---|---|---|
| meeting_id | bigint | FK |
| user_id | bigint | FK |
| attended | boolean | marked after meeting |

---

### 4.12 `customers`

External customer accounts for support and installation tracking.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | integer | PK | |
| name | string | NOT NULL | |
| company | string | | |
| email | string | NOT NULL, unique (case-insensitive) | |
| phone | string | | |
| contact_person | string | | internal contact |
| notes | text | | |
| active | boolean | NOT NULL, DEFAULT true | soft-delete |
| created_at / updated_at | datetime | NOT NULL | |

**Associations:** has_many customer_tickets (dependent: destroy), installations (dependent: destroy)

**Validations:** name presence; email presence, uniqueness (case-insensitive), format (URI::MailTo::EMAIL_REGEXP)

**Scopes:** `.active`, `.inactive`

**Methods:** `#display_name` → "Name (Company)" or "Name"; `#installed_projects` → unique projects from installations

---

### 4.13 `customer_tickets`

Support tickets submitted by or on behalf of customers.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | integer | PK | |
| customer_id | integer | NOT NULL, FK | |
| assigned_to_id | integer | FK → users | optional |
| internal_ticket_id | integer | FK → tickets | optional |
| title | string | NOT NULL | |
| body | text | | |
| status | integer | NOT NULL, DEFAULT 0 | enum below |
| priority | integer | NOT NULL, DEFAULT 1 | enum below |
| resolved_at | datetime | | |
| created_at / updated_at | datetime | NOT NULL | |

**Status enum (prefix: true):** `open(0)` `in_progress(1)` `waiting_for_customer(2)` `resolved(3)` `closed(4)`

**Priority enum (prefix: true):** `low(0)` `medium(1)` `high(2)` `critical(3)`

**Scopes:** `.open_tickets` (open + in_progress + waiting), `.resolved`, `.high_priority`

**Methods:** `#resolve!` sets status to resolved + resolved_at timestamp; `#link_to_internal!(ticket)` links to internal dev ticket

---

### 4.14 `installations`

Tracks which software version is installed at a customer site.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | integer | PK | |
| customer_id | integer | NOT NULL, FK | |
| project_id | integer | FK | optional — which project owns this software |
| deployment_id | integer | FK | optional — which deployment produced this install |
| software_name | string | NOT NULL | |
| version | string | NOT NULL | |
| environment | string | NOT NULL, DEFAULT 'production' | production/staging/uat/development |
| status | integer | NOT NULL, DEFAULT 0 | enum below |
| installed_at | datetime | | |
| notes | text | | |
| created_at / updated_at | datetime | NOT NULL | |

**Indexes:** `[customer_id, software_name]` composite; `[status]`

**Status enum (prefix: true):** `active(0)` `pending(1)` `outdated(2)` `decommissioned(3)` `failed(4)`

**ENVIRONMENTS constant:** `%w[production staging uat development]`

**Callback:** `after_create :mark_previous_as_outdated` — when a new Active installation is saved, all previous Active installations for the same customer + software_name are automatically set to Outdated.

---

### 4.15 `branches`

Git branches created from tickets.

| Column | Type | Notes |
|---|---|---|
| project_id | bigint | FK |
| ticket_id | bigint | FK |
| name | string | NOT NULL |
| status | integer | enum: active(0) merged(1) deleted(2) |
| created_at_gitea | datetime | timestamp from Gitea webhook |

---

### 4.16 `pull_requests`

Pull / merge requests from Gitea.

| Column | Type | Notes |
|---|---|---|
| project_id | bigint | FK |
| ticket_id | bigint | FK (optional) |
| pr_number | integer | NOT NULL |
| title | string | NOT NULL |
| status | integer | enum: open(0) review(1) merged(2) closed(3) |

---

### 4.17 `client_accounts`

Legacy CRM-style account records (predecessor to the full Customer module).

| Column | Type | Notes |
|---|---|---|
| name | string | |
| contact_name | string | |
| contact_phone | string | |
| email | string | |
| notes | text | |

---

### 4.18 `comments` (polymorphic)

Comments attached to tickets, documents, meetings, or pull requests.

| Column | Type | Constraints |
|---|---|---|
| commentable_type | string | NOT NULL (polymorphic type) |
| commentable_id | bigint | NOT NULL (polymorphic id) |
| author_id | bigint | FK → users |
| body | text | |

---

### 4.19 `notifications` (polymorphic recipient)

In-app notification records.

| Column | Type | Notes |
|---|---|---|
| recipient_type | string | polymorphic |
| recipient_id | bigint | polymorphic |
| type | string | notification class name (Noticed) |
| params | text | JSON serialised payload |
| read_at | datetime | null = unread |

---

### 4.20 `ticket_watchers`

Join table — users watching tickets for change notifications.

| Column | Type |
|---|---|
| ticket_id | bigint |
| user_id | bigint |

---

### 4.21 Active Storage tables

Three standard Rails Active Storage tables: `active_storage_blobs`, `active_storage_attachments`, `active_storage_variant_records`. Used for file attachments on `Document`.

---

### 4.22 Tagging tables (`taggings`, `tags`)

Provided by `acts-as-taggable-on`. Used on `Ticket` (tags, labels) and `Document` (tags).

---

## 5. Entity-Relationship Overview

```
User ──────< Ticket (assignee)
User ──────< CiRun (triggered_by)
User ──────< Deployment (deployed_by)
User ──────< Document (author)
User ──────< MeetingAttendee >──── Meeting
User ──────< TicketWatcher >────── Ticket
User ──────< Notification (recipient)
User ──────< CustomerTicket (assigned_to)

Project ───< Sprint
Project ───< Milestone ──────< Ticket
Project ───< Ticket ─────────< Branch
                         │───< PullRequest
                         │───< CiRun ────< TestResult
Project ───< CiRun
Project ───< Deployment ────< Installation
Project ───< Document
Project ───< Meeting
Project ───< Branch
Project ───< PullRequest
Project ───< Installation

Customer ──< CustomerTicket (can link → Ticket)
Customer ──< Installation (can link → Deployment, Project)

Comment (polymorphic: Ticket | Document | Meeting | PullRequest)
Notification (polymorphic recipient: User | ...)
```

---

## 6. Authentication & Authorisation

### Authentication — Devise

- Modules in use: `database_authenticatable`, `registerable`, `recoverable`, `rememberable`, `validatable`
- Custom `Users::SessionsController` (locale skipped on sign-in page)
- Custom `Users::RegistrationsController`
- Post-login redirect → `today_path` (personalised "My Day" page)

### Authorisation — Pundit

- `ApplicationController` includes `Pundit::Authorization`
- `rescue_from Pundit::NotAuthorizedError` → redirects back with flash alert
- Role hierarchy: `developer(0)` < `team_lead(1)` < `project_manager(2)` < `admin(3)` / `qa(4)`

---

## 7. Webhooks

| Endpoint | Source | Verification |
|---|---|---|
| `POST /webhooks/gitea` | Gitea server | HMAC-SHA256 `X-Gitea-Signature` header |
| `POST /webhooks/jenkins` | Jenkins | Secret token in header |

Webhook controller skips CSRF protection. Events handled:

- **Gitea push** → creates/updates `Branch` record
- **Gitea pull_request** → creates/updates `PullRequest` record
- **Gitea issues** → creates `Ticket` from Gitea issue
- **Jenkins build** → creates/updates `CiRun`; triggers failure notification job

---

## 8. Background Jobs (Solid Queue)

| Job | Trigger | Action |
|---|---|---|
| `TicketMailer#assigned` | Ticket assigned | Emails new assignee |
| `TicketMailer#status_changed` | Ticket status change | Emails assignee + watchers |
| `TicketMailer#ci_failed` | CI run fails | Emails ticket assignee |
| `TicketMailer#deploy_failed` | Deployment fails | Emails deployer |
| Branch creation job | Ticket assigned | Creates branch in Gitea via API |

---

## 9. Internationalisation

- **Locales:** English (`en`) and Hebrew (`he`)
- **RTL:** `<html dir="rtl">` and `is-rtl` body class applied when locale is `he`
- **User preference:** `preferred_language` column on User, stored as `"en"` / `"he"`
- **Locale detection order:** `params[:locale]` → `current_user.preferred_language` → `I18n.default_locale`
- **Translation files:** `config/locales/en.yml`, `config/locales/he.yml`

---

## 10. Key URL Routes

| Path | Controller#Action | Notes |
|---|---|---|
| `/` | `dashboard#index` | Root, requires auth |
| `/today` | `today#index` | Developer's personalised day view |
| `/dashboard` | `dashboard#index` | Team-wide dashboard |
| `/projects` | `projects#index` | Project list |
| `/projects/:id/tickets` | `tickets#index` | Tickets per project |
| `/tickets/:id` | `tickets#show` | Shallow-nested ticket |
| `/projects/:id/ci_dashboard` | `projects#ci_dashboard` | CI stats page |
| `/customers` | `customers#index` | Customer list |
| `/customers/:id/customer_tickets` | `customer_tickets#index` | Support tickets |
| `/customers/:id/installations` | `installations#index` | Installations |
| `/webhooks/gitea` | `webhooks#gitea` | Gitea webhook receiver |
| `/webhooks/jenkins` | `webhooks#jenkins` | Jenkins webhook receiver |
| `/reports/ci_summary` | `reports/ci_summary#index` | CI reports |
| `/admin/users` | `admin/users#index` | User management |

---

## 11. Environment Variables

| Variable | Default | Purpose |
|---|---|---|
| `JENKINS_URL` | `http://localhost:8080` | Jenkins base URL for CI links |
| `GITEA_URL` | `http://localhost:3000` | Gitea server URL |
| `JITSI_URL` | `https://meet.jit.si` | Jitsi video call base URL |
| `MAILER_FROM` | `devteam@yourcompany.com` | From address for transactional email |
| `SENTRY_DSN` | — | Sentry error tracking DSN |
| `RAILS_MASTER_KEY` | — | Encrypts credentials |
| `SECRET_KEY_BASE` | — | Rails session signing |
