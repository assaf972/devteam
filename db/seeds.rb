# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Seeding..."

# ─────────────────────────────────────────────────────────────────
# Internal users (developers, leads, admin)
# ─────────────────────────────────────────────────────────────────
users_data = [
  { name: "Assaf Goldstein",   email: "assaf@devteam.local",   role: :admin           },
  { name: "Yael Cohen",        email: "yael@devteam.local",    role: :team_lead        },
  { name: "Noam Levi",         email: "noam@devteam.local",    role: :developer        },
  { name: "Dana Mizrahi",      email: "dana@devteam.local",    role: :developer        },
  { name: "Oren Shapiro",      email: "oren@devteam.local",    role: :developer        },
  { name: "Michal Ben-David",  email: "michal@devteam.local",  role: :qa               },
  { name: "Tal Katz",          email: "tal@devteam.local",     role: :project_manager  },
  { name: "Avi Peretz",        email: "avi@devteam.local",     role: :developer        }
]

users = users_data.map do |attrs|
  User.find_or_create_by!(email: attrs[:email]) do |u|
    u.name     = attrs[:name]
    u.role     = attrs[:role]
    u.password = "password123"
    u.preferred_language = :en
  end
end

puts "  ✓ #{users.size} internal users"

# ─────────────────────────────────────────────────────────────────
# Customers (portal accounts — parent of CustomerUser)
# ─────────────────────────────────────────────────────────────────
clients_data = [
  { name: "John Smith",    company: "Acme Corp",        email: "contact@acme.example",   phone: "+1-555-0101", contact_person: "John Smith"    },
  { name: "Sarah Connor",  company: "Globex Solutions",  email: "info@globex.example",    phone: "+1-555-0202", contact_person: "Sarah Connor"  },
  { name: "Bill Lumbergh", company: "Initech Ltd",       email: "hello@initech.example",  phone: "+1-555-0303", contact_person: "Bill Lumbergh" }
]

clients = clients_data.map do |attrs|
  Customer.find_or_create_by!(email: attrs[:email]) do |c|
    c.name           = attrs[:name]
    c.company        = attrs[:company]
    c.phone          = attrs[:phone]
    c.contact_person = attrs[:contact_person]
    c.active         = true
  end
end

puts "  ✓ #{clients.size} customers"

# ─────────────────────────────────────────────────────────────────
# Customer portal users (one or two per client)
# ─────────────────────────────────────────────────────────────────
customer_users_data = [
  { name: "John Smith",     email: "john@acme.example",       client: clients[0] },
  { name: "Amy Johnson",    email: "amy@acme.example",        client: clients[0] },
  { name: "Sarah Connor",   email: "sarah@globex.example",    client: clients[1] },
  { name: "Miles Dyson",    email: "miles@globex.example",    client: clients[1] },
  { name: "Bill Lumbergh",  email: "bill@initech.example",    client: clients[2] }
]

customer_users = customer_users_data.map do |attrs|
  CustomerUser.find_or_create_by!(email: attrs[:email]) do |cu|
    cu.name        = attrs[:name]
    cu.customer    = attrs[:client]
    cu.password    = "password123"
    cu.password_confirmation = "password123"
  end
end

puts "  ✓ #{customer_users.size} customer portal users"

# ─────────────────────────────────────────────────────────────────
# Projects  (5 real projects from the team email + this app)
# ─────────────────────────────────────────────────────────────────
projects_data = [
  {
    name:           "Print Server / TDI",
    description:    "Windows print server and TDI print management system. " \
                    "Handles print queue management, driver distribution, and " \
                    "enterprise printer configuration.",
    tech_stack:     "C# .NET 4.8.1, VB.net, Windows Print Spooler, WinForms",
    repo_url:       "http://gitea.local/devteam/print-server-tdi",
    default_branch: "main",
    active:         true
  },
  {
    name:           "TDI2",
    description:    "Next-generation TDI platform built on ASP.NET MVC Core 10. " \
                    "Multi-threaded order processing with RabbitMQ messaging, " \
                    "Entity Framework Core ORM, and Serilog structured logging.",
    tech_stack:     "ASP.NET MVC Core 10, Visual Studio 2026, IIS, Razor Pages, " \
                    "NuGet, RabbitMQ, EntityFrameworkCore, Serilog, SQL Server, " \
                    "JavaScript, HTML, CSS, Bootstrap, JSON/XML, NUnit, Multithread",
    repo_url:       "http://gitea.local/devteam/tdi2",
    default_branch: "main",
    active:         true
  },
  {
    name:           "Digital Internet Services",
    description:    "Customer-facing web portal with Vue 3 SPA frontend and " \
                    "NestJS API backend. Deployed using Docker Windows Containers " \
                    "with SQL Server persistence.",
    tech_stack:     "Vue 3 (Composition API + TypeScript), Vite, NestJS (Node.js), " \
                    "SQL Server, Docker (Windows Containers)",
    repo_url:       "http://gitea.local/devteam/digital-internet-services",
    default_branch: "main",
    active:         true
  },
  {
    name:           "Work Management System",
    description:    "Internal work-item tracking platform. Next.js 16 frontend " \
                    "running on Bun runtime with PostgreSQL 16 storage and " \
                    "Jenkins CI/CD pipelines.",
    tech_stack:     "Next.js 16, TypeScript, Bun (runtime), PostgreSQL 16, Jenkins",
    repo_url:       "http://gitea.local/devteam/work-management-system",
    default_branch: "main",
    active:         true
  },
  {
    name:           "DevTeam Hub",
    description:    "This application. Internal DevOps dashboard aggregating CI, " \
                    "deployments, pull requests, tickets, and team communication " \
                    "in a single Slack-style interface.",
    tech_stack:     "Rails 8.1, Ruby 3.4, SQLite3, Hotwire (Turbo + Stimulus), " \
                    "Bulma CSS, Devise, Pundit, ActiveStorage",
    repo_url:       "http://gitea.local/devteam/dev-team-hub",
    default_branch: "main",
    active:         true
  }
]

projects = projects_data.map do |attrs|
  Project.find_or_create_by!(name: attrs[:name]) do |p|
    p.assign_attributes(attrs)
  end
end

puts "  ✓ #{projects.size} projects (#{projects.count(&:active?)} active)"

# ─────────────────────────────────────────────────────────────────
# Project memberships
# ─────────────────────────────────────────────────────────────────
admin      = users.find { |u| u.admin? }
team_lead  = users.find { |u| u.team_lead? }
developers = users.select { |u| u.developer? }  # noam, dana, oren, avi
qa_user    = users.find { |u| u.qa? }
pm_user    = users.find { |u| u.project_manager? }

noam, dana, oren, avi = developers

memberships = [
  # Print Server / TDI
  { project: projects[0], user: team_lead, role: :lead      },
  { project: projects[0], user: noam,      role: :developer },
  { project: projects[0], user: dana,      role: :developer },
  { project: projects[0], user: qa_user,   role: :qa        },

  # TDI2
  { project: projects[1], user: team_lead, role: :lead      },
  { project: projects[1], user: noam,      role: :developer },
  { project: projects[1], user: dana,      role: :developer },
  { project: projects[1], user: oren,      role: :developer },
  { project: projects[1], user: avi,       role: :developer },
  { project: projects[1], user: qa_user,   role: :qa        },

  # Digital Internet Services
  { project: projects[2], user: team_lead, role: :lead      },
  { project: projects[2], user: noam,      role: :developer },
  { project: projects[2], user: dana,      role: :developer },
  { project: projects[2], user: oren,      role: :developer },
  { project: projects[2], user: avi,       role: :developer },
  { project: projects[2], user: qa_user,   role: :qa        },

  # Work Management System
  { project: projects[3], user: pm_user,   role: :lead      },
  { project: projects[3], user: noam,      role: :developer },
  { project: projects[3], user: dana,      role: :developer },
  { project: projects[3], user: oren,      role: :developer },
  { project: projects[3], user: avi,       role: :developer },
  { project: projects[3], user: qa_user,   role: :qa        },

  # DevTeam Hub
  { project: projects[4], user: admin,     role: :lead      },
  { project: projects[4], user: team_lead, role: :developer },
  { project: projects[4], user: noam,      role: :developer },
  { project: projects[4], user: dana,      role: :developer },
  { project: projects[4], user: qa_user,   role: :qa        }
]

memberships.each do |m|
  ProjectMembership.find_or_create_by!(project: m[:project], user: m[:user]) do |pm|
    pm.role = m[:role]
  end
end

puts "  ✓ #{memberships.size} project memberships"

# ─────────────────────────────────────────────────────────────────
# Chat rooms
# ─────────────────────────────────────────────────────────────────
chat_rooms_data = [
  { name: "general",   description: "Company-wide announcements and chat",        room_type: :general,      project: nil          },
  { name: "random",    description: "Off-topic and fun stuff",                    room_type: :general,      project: nil          },
  { name: "incidents", description: "Production incident coordination",           room_type: :incident,     project: nil          },
  { name: "releases",  description: "Release announcements",                      room_type: :announcement, project: nil          },
  { name: "tdi",       description: "Print Server / TDI day-to-day discussion",  room_type: :project_room, project: projects[0]  },
  { name: "tdi2",      description: "TDI2 team channel",                         room_type: :project_room, project: projects[1]  },
  { name: "dis",       description: "Digital Internet Services channel",         room_type: :project_room, project: projects[2]  },
  { name: "wms",       description: "Work Management System channel",            room_type: :project_room, project: projects[3]  },
  { name: "devteam",   description: "DevTeam Hub dev channel",                   room_type: :project_room, project: projects[4]  }
]

chat_rooms_data.each do |attrs|
  ChatRoom.find_or_create_by!(name: attrs[:name]) do |r|
    r.description = attrs[:description]
    r.room_type   = attrs[:room_type]
    r.archived    = false
    r.project     = attrs[:project] if attrs[:project]
  end
end

puts "  ✓ #{chat_rooms_data.size} chat rooms"

# ─────────────────────────────────────────────────────────────────
# Tickets / Stories
# Each entry: project, kind, level, title, description,
#             status, priority, owner, assignee,
#             dev_estimate_hours, tester_estimate_hours,
#             how_to_reproduce (optional — bugs/hotfixes),
#             pr_number (optional), pr_url (optional),
#             attach_spec (true = attach a spec/design document)
# ─────────────────────────────────────────────────────────────────
tickets_data = [
  # ── Print Server / TDI ───────────────────────────────────────────
  {
    project:               projects[0],
    kind:           :story,
    level:                 :complex,
    title:                 "Add PDF export for print queue jobs",
    description:           "Allow operators to export the current print queue as a PDF report " \
                           "including job ID, document name, page count, and submission time. " \
                           "The export should support filtering by printer and date range.",
    status:                :in_progress,
    priority:              :medium,
    owner:                 team_lead,
    assignee:              noam,
    dev_estimate_hours:    16.0,
    tester_estimate_hours: 4.0,
    attach_spec:           true
  },
  {
    project:               projects[0],
    kind:           :story,
    level:                 :moderate,
    title:                 "Support duplex printing profiles per printer",
    description:           "Add per-printer duplex profile configuration. Operators should be " \
                           "able to define default duplex mode (none, long-edge, short-edge) " \
                           "per printer. Profile must persist across server restarts.",
    status:                :backlog,
    priority:              :low,
    owner:                 pm_user,
    assignee:              nil,
    dev_estimate_hours:    8.0,
    tester_estimate_hours: 2.0,
    attach_spec:           true
  },
  {
    project:               projects[0],
    kind:           :bug_fix,
    level:                 :complex,
    how_to_reproduce:      "1. Connect a printer and start a multi-page print job\n2. Disconnect the printer's network cable mid-job\n3. Observe: job stays in 'Sending' status indefinitely\n4. Expected: job marked 'Failed' after retry timeout with configurable backoff",
    title:                 "Print jobs stuck in queue after network timeout",
    description:           "When the network connection to a printer is lost mid-job, the print " \
                           "spooler does not recover — jobs remain in the queue with status " \
                           "'Sending' indefinitely. Expected: auto-retry with configurable " \
                           "backoff, job marked 'Failed' after max retries.",
    status:                :open,
    priority:              :critical,
    owner:                 team_lead,
    assignee:              dana,
    dev_estimate_hours:    4.0,
    tester_estimate_hours: 1.0,
    attach_spec:           false
  },
  {
    project:               projects[0],
    kind:           :bug_fix,
    level:                 :simple,
    how_to_reproduce:      "1. Set Windows locale to he-IL\n2. Open the print queue manager\n3. Add a print job for any document\n4. Observe: paper size defaults to Letter (8.5x11)\n5. Expected: paper size should default to A4 for he-IL locale",
    title:                 "Wrong paper size selected for Hebrew locale",
    description:           "When the system locale is set to he-IL, the default paper size " \
                           "falls back to Letter instead of A4. Root cause is likely a missing " \
                           "locale mapping in PaperSizeHelper.vb.",
    status:                :in_review,
    priority:              :high,
    owner:                 qa_user,
    assignee:              oren,
    dev_estimate_hours:    6.0,
    tester_estimate_hours: 2.0,
    pr_number:             12,
    pr_url:                "http://gitea.local/devteam/print-server-tdi/pulls/12",
    attach_spec:           false
  },
  {
    project:               projects[0],
    kind:           :meta_story,
    level:                 :simple,
    title:                 "Upgrade .NET runtime from 4.8.0 to 4.8.1",
    description:           "Update project target framework to .NET 4.8.1. Run full regression " \
                           "suite after upgrade. Update NuGet dependencies to compatible versions. " \
                           "Test on Windows Server 2019 and 2022.",
    status:                :done,
    priority:              :medium,
    owner:                 admin,
    assignee:              avi,
    dev_estimate_hours:    8.0,
    tester_estimate_hours: 8.0,
    attach_spec:           false
  },

  # ── TDI2 ─────────────────────────────────────────────────────────
  {
    project:               projects[1],
    kind:           :story,
    level:                 :complex,
    title:                 "Implement RabbitMQ dead-letter exchange for failed message retry",
    description:           "Configure a dead-letter exchange (DLX) on the order-processing queue. " \
                           "Messages that fail after 3 attempts should be routed to a DLX with a " \
                           "30-minute TTL before re-queuing. Add Serilog events for each DLX routing.",
    status:                :in_progress,
    priority:              :high,
    owner:                 team_lead,
    assignee:              noam,
    dev_estimate_hours:    24.0,
    tester_estimate_hours: 8.0,
    attach_spec:           true
  },
  {
    project:               projects[1],
    kind:           :story,
    level:                 :simple,
    title:                 "Add Serilog structured logging to all MVC controllers",
    description:           "Replace Console.WriteLine / Debug.WriteLine calls with Serilog " \
                           "ILogger<T> structured logging. Include request correlation ID " \
                           "(from X-Correlation-ID header) in every log entry. Configure " \
                           "Serilog sinks: File (rolling daily) + Application Insights.",
    status:                :done,
    priority:              :medium,
    owner:                 pm_user,
    assignee:              dana,
    dev_estimate_hours:    12.0,
    tester_estimate_hours: 4.0,
    attach_spec:           false
  },
  {
    project:               projects[1],
    kind:           :story,
    level:                 :expert,
    title:                 "Migrate data layer to EntityFrameworkCore 9 code-first",
    description:           "Replace the legacy LINQ-to-SQL layer with EF Core 9 code-first " \
                           "migrations. Map all existing stored procedures to EF Core raw SQL " \
                           "calls or equivalent LINQ expressions. Target SQL Server 2022 " \
                           "compatibility level 160.",
    status:                :backlog,
    priority:              :high,
    owner:                 admin,
    assignee:              nil,
    dev_estimate_hours:    32.0,
    tester_estimate_hours: 16.0,
    attach_spec:           true
  },
  {
    project:               projects[1],
    kind:           :bug_fix,
    level:                 :expert,
    how_to_reproduce:      "1. Run OrderProcessor load test with 60+ concurrent threads\n2. Submit 100 identical order IDs simultaneously\n3. Check the database for duplicate Order records\n4. Observe: same order processed more than once, creating duplicate invoices\n5. Expected: each order processed exactly once (idempotent)",
    title:                 "Race condition in multi-threaded order processor",
    description:           "Under high load (>50 concurrent threads) the OrderProcessor " \
                           "occasionally processes the same order twice, resulting in duplicate " \
                           "invoices. Suspected cause: missing lock around order-status read-then-" \
                           "update. Needs a distributed lock via SQL Server application locks.",
    status:                :in_review,
    priority:              :critical,
    owner:                 qa_user,
    assignee:              oren,
    dev_estimate_hours:    16.0,
    tester_estimate_hours: 8.0,
    pr_number:             34,
    pr_url:                "http://gitea.local/devteam/tdi2/pulls/34",
    attach_spec:           false
  },
  {
    project:               projects[1],
    kind:           :bug_fix,
    level:                 :complex,
    how_to_reproduce:      "1. Log in as a tenant with >500k orders\n2. Navigate to Reports → Monthly Revenue\n3. Select any month with full data\n4. Observe: request times out after 30 seconds\n5. Run EXPLAIN on generated SQL — full table scan on Orders table confirmed",
    title:                 "SQL Server query timeout on large report generation",
    description:           "The monthly revenue report times out (30 s) for tenants with " \
                           ">500k orders. The query performs a full table scan on Orders " \
                           "because the WHERE clause casts the date column. Fix: add a " \
                           "computed persisted column + filtered index.",
    status:                :open,
    priority:              :high,
    owner:                 team_lead,
    assignee:              avi,
    dev_estimate_hours:    8.0,
    tester_estimate_hours: 4.0,
    attach_spec:           false
  },

  # ── Digital Internet Services ─────────────────────────────────────
  {
    project:               projects[2],
    kind:           :story,
    level:                 :complex,
    title:                 "Build Vue 3 Composition API client statistics dashboard",
    description:           "Create a multi-panel statistics dashboard using Vue 3 Composition " \
                           "API + TypeScript. Panels: active sessions, bandwidth usage, top " \
                           "routes, error rate. Data sourced from NestJS /api/stats endpoints. " \
                           "Use Pinia for state management and Chart.js for visualisations.",
    status:                :in_progress,
    priority:              :high,
    owner:                 team_lead,
    assignee:              noam,
    dev_estimate_hours:    40.0,
    tester_estimate_hours: 16.0,
    attach_spec:           true
  },
  {
    project:               projects[2],
    kind:           :story,
    level:                 :complex,
    title:                 "Configure Docker Windows Container CI/CD deployment pipeline",
    description:           "Build a Docker Windows Container image for the NestJS API. " \
                           "Define multi-stage Dockerfile (build → runtime). Configure the " \
                           "Jenkins pipeline to: build image, push to internal registry, " \
                           "deploy to staging via docker service update.",
    status:                :backlog,
    priority:              :medium,
    owner:                 pm_user,
    assignee:              nil,
    dev_estimate_hours:    24.0,
    tester_estimate_hours: 8.0,
    attach_spec:           true
  },
  {
    project:               projects[2],
    kind:           :story,
    level:                 :complex,
    title:                 "NestJS JWT authentication with refresh token rotation",
    description:           "Implement JWT access + refresh token flow in the NestJS AuthModule. " \
                           "Access token TTL: 15 min. Refresh token TTL: 7 days with rotation " \
                           "on each use. Revocation list stored in SQL Server. " \
                           "Guard all protected routes with @UseGuards(JwtAuthGuard).",
    status:                :done,
    priority:              :critical,
    owner:                 admin,
    assignee:              dana,
    dev_estimate_hours:    20.0,
    tester_estimate_hours: 8.0,
    attach_spec:           false
  },
  {
    project:               projects[2],
    kind:           :bug_fix,
    level:                 :simple,
    how_to_reproduce:      "1. Log in to the application\n2. Navigate to any authenticated page\n3. Press F5 (hard browser refresh)\n4. Observe: user is logged out / Pinia store is cleared\n5. Expected: session should persist across browser refreshes",
    title:                 "Pinia store state lost on browser refresh (missing persist plugin)",
    description:           "After a hard browser refresh all Pinia store state is cleared, " \
                           "forcing the user to re-authenticate. Fix: install " \
                           "pinia-plugin-persistedstate and configure localStorage persistence " \
                           "for the auth and session stores.",
    status:                :open,
    priority:              :medium,
    owner:                 qa_user,
    assignee:              oren,
    dev_estimate_hours:    4.0,
    tester_estimate_hours: 2.0,
    attach_spec:           false
  },
  {
    project:               projects[2],
    kind:           :bug_fix,
    level:                 :complex,
    how_to_reproduce:      "1. Run load test with 200 concurrent virtual users (k6 or Artillery)\n2. Monitor SQL Server connection count via sys.dm_exec_connections\n3. Observe: requests fail with ConnectionTimeoutError after ~60 seconds\n4. Expected: connection pool handles 200+ concurrent users without exhaustion",
    title:                 "SQL Server connection pool exhaustion under concurrent load",
    description:           "Under load testing (200 concurrent users) the SQL Server connection " \
                           "pool is exhausted after ~60 seconds. TypeORM default pool max is 10. " \
                           "Increase pool size to 50 and enable connection timeout monitoring. " \
                           "Also audit for missing .release() calls in raw query paths.",
    status:                :in_review,
    priority:              :critical,
    owner:                 team_lead,
    assignee:              avi,
    dev_estimate_hours:    8.0,
    tester_estimate_hours: 4.0,
    pr_number:             18,
    pr_url:                "http://gitea.local/devteam/digital-internet-services/pulls/18",
    attach_spec:           false
  },

  # ── Work Management System ────────────────────────────────────────
  {
    project:               projects[3],
    kind:           :story,
    level:                 :complex,
    title:                 "Kanban board with drag-and-drop using Next.js 16 Server Actions",
    description:           "Implement a drag-and-drop Kanban board for sprint tickets using " \
                           "@dnd-kit/core. Board columns: Backlog, In Progress, In Review, Done. " \
                           "Column transitions should call Next.js 16 Server Actions to persist " \
                           "status changes. Optimistic UI updates required.",
    status:                :in_progress,
    priority:              :high,
    owner:                 pm_user,
    assignee:              noam,
    dev_estimate_hours:    32.0,
    tester_estimate_hours: 12.0,
    attach_spec:           true
  },
  {
    project:               projects[3],
    kind:           :story,
    level:                 :moderate,
    title:                 "PostgreSQL full-text search for tickets and projects",
    description:           "Add a tsvector column to the tickets table populated from title + " \
                           "description. Create a GIN index. Expose a /search endpoint backed by " \
                           "to_tsquery. Frontend: debounced search input with highlighted " \
                           "matches using ts_headline.",
    status:                :backlog,
    priority:              :medium,
    owner:                 admin,
    assignee:              nil,
    dev_estimate_hours:    16.0,
    tester_estimate_hours: 4.0,
    attach_spec:           true
  },
  {
    project:               projects[3],
    kind:           :story,
    level:                 :moderate,
    title:                 "Jenkins CI pipeline integration with Bun test runner",
    description:           "Configure Jenkinsfile to run bun test --reporter=junit, parse " \
                           "the JUnit XML output, and publish test results in Jenkins. " \
                           "Pipeline stages: Install → Lint → Test → Build → Deploy to staging. " \
                           "Cache bun.lock in Jenkins workspace for faster installs.",
    status:                :done,
    priority:              :medium,
    owner:                 pm_user,
    assignee:              dana,
    dev_estimate_hours:    20.0,
    tester_estimate_hours: 8.0,
    attach_spec:           false
  },
  {
    project:               projects[3],
    kind:           :bug_fix,
    level:                 :moderate,
    how_to_reproduce:      "1. Open the project in VSCode on Windows (WSL2)\n2. Start the dev server: bun run dev\n3. Rename any .ts source file in VSCode (F2 or right-click → Rename)\n4. Observe: Bun dev server crashes with ENOENT error\n5. Workaround: set BUN_HMR_POLL=1 bun run dev",
    title:                 "Bun hot-reload crashes on Windows WSL2 after file rename",
    description:           "When a source file is renamed in VSCode on Windows (which triggers " \
                           "a delete + create inotify event pair), Bun's HMR watcher crashes " \
                           "with ENOENT. Workaround: enable polling via BUN_HMR_POLL=1. " \
                           "Proper fix: debounce inotify events in the watcher.",
    status:                :open,
    priority:              :high,
    owner:                 qa_user,
    assignee:              oren,
    dev_estimate_hours:    6.0,
    tester_estimate_hours: 2.0,
    attach_spec:           false
  },
  {
    project:               projects[3],
    kind:           :bug_fix,
    level:                 :complex,
    how_to_reproduce:      "1. Open the sprint detail page for a sprint with >1000 tickets\n2. Apply a status filter (e.g. in_progress)\n3. Run EXPLAIN ANALYZE on the generated SQL in psql\n4. Observe: Seq Scan on tickets instead of Index Scan\n5. Expected: GIN index on (sprint_id, status) should be used",
    title:                 "PostgreSQL query planner ignores GIN index on sprint filter",
    description:           "The sprint ticket list query performs a sequential scan on tickets " \
                           "even though a GIN index on (sprint_id, status) exists. Cause: the " \
                           "ORM is casting sprint_id to text in the WHERE clause. Fix by " \
                           "ensuring the parameter type matches the column type (bigint).",
    status:                :in_review,
    priority:              :high,
    owner:                 team_lead,
    assignee:              avi,
    dev_estimate_hours:    8.0,
    tester_estimate_hours: 4.0,
    pr_number:             9,
    pr_url:                "http://gitea.local/devteam/work-management-system/pulls/9",
    attach_spec:           false
  },
  {
    project:               projects[3],
    kind:           :spike,
    level:                 :moderate,
    title:                 "Evaluate Bun native SQLite vs PostgreSQL for local dev workflow",
    description:           "Investigate using Bun's built-in SQLite for local development " \
                           "(faster setup, zero deps) vs keeping PostgreSQL everywhere. " \
                           "Produce a short decision document covering: performance on test " \
                           "suite, migration tooling compatibility, and Docker impact.",
    status:                :backlog,
    priority:              :low,
    owner:                 admin,
    assignee:              nil,
    dev_estimate_hours:    16.0,
    tester_estimate_hours: 0.0,
    attach_spec:           true
  },

  # ── DevTeam Hub (this app) ────────────────────────────────────────
  {
    project:               projects[4],
    kind:           :story,
    level:                 :moderate,
    title:                 "Project membership management with role-based email notifications",
    description:           "Admins and project leads can add/remove users from projects via the " \
                           "project show page. Adding a member sends a ProjectMailer email and " \
                           "creates an Activity record (event_type: member_added). Roles: " \
                           "developer, viewer, lead, qa.",
    status:                :done,
    priority:              :high,
    owner:                 admin,
    assignee:              admin,
    dev_estimate_hours:    24.0,
    tester_estimate_hours: 8.0,
    attach_spec:           false
  },
  {
    project:               projects[4],
    kind:           :story,
    level:                 :moderate,
    title:                 "Activity feed with APM exception ingestion via webhook",
    description:           "Timeline activity feed on each project page showing member changes, " \
                           "CI results, deployments, and exceptions. APM exceptions ingested via " \
                           "POST /webhooks/exception (verified with X-APM-Key header). " \
                           "Activity model has 10 event types with icons and metadata.",
    status:                :done,
    priority:              :high,
    owner:                 admin,
    assignee:              team_lead,
    dev_estimate_hours:    16.0,
    tester_estimate_hours: 4.0,
    attach_spec:           false
  },
  {
    project:               projects[4],
    kind:           :story,
    level:                 :complex,
    title:                 "Slack-style 3-column layout with Hotwire real-time chat",
    description:           "Redesign the app shell as a 3-column layout (dark sidebar, main " \
                           "content, right notifications panel). Chat rooms with Turbo Frames " \
                           "for real-time message updates. Sidebar shows project CI status, " \
                           "deployments, and PR counts with accordion per project.",
    status:                :done,
    priority:              :high,
    owner:                 admin,
    assignee:              noam,
    dev_estimate_hours:    40.0,
    tester_estimate_hours: 8.0,
    attach_spec:           false
  },
  {
    project:               projects[4],
    kind:           :story,
    level:                 :moderate,
    title:                 "Auto-create git branch and notify assignee on ticket assignment",
    description:           "When a ticket is assigned to a developer, automatically create a " \
                           "branch on the Gitea repo (feature/T-{id}-{slug} or bugfix/...) " \
                           "and send the assignee an in-app notification with the exact " \
                           "git fetch + git checkout command they need to run.",
    status:                :in_progress,
    priority:              :high,
    owner:                 admin,
    assignee:              dana,
    dev_estimate_hours:    16.0,
    tester_estimate_hours: 4.0,
    attach_spec:           true
  },
  {
    project:               projects[4],
    kind:           :bug_fix,
    level:                 :simple,
    how_to_reproduce:      "1. Open any project page with the sidebar visible\n2. Expand a project accordion section in the sidebar\n3. Click any Turbo navigation link (tab, ticket, etc.)\n4. Observe: sidebar accordion collapses back to default state\n5. Expected: accordion open/close state should persist across Turbo navigation",
    title:                 "Sidebar accordion state lost on Turbo navigation",
    description:           "When navigating between pages via Turbo Drive, the sidebar project " \
                           "accordion forgets which sections were open. The Stimulus controller " \
                           "needs to persist accordion state in sessionStorage and restore it " \
                           "on connect().",
    status:                :open,
    priority:              :medium,
    owner:                 qa_user,
    assignee:              oren,
    dev_estimate_hours:    2.0,
    tester_estimate_hours: 1.0,
    attach_spec:           false
  },
  {
    project:               projects[4],
    kind:           :spike,
    level:                 :moderate,
    title:                 "Evaluate ActionCable for real-time chat vs Turbo Streams polling",
    description:           "Investigate whether replacing the current Turbo Frames + form-submit " \
                           "chat with ActionCable WebSocket broadcasts would improve UX without " \
                           "adding operational complexity (Redis pub/sub, cable config). " \
                           "Document latency, resource usage, and deployment implications.",
    status:                :backlog,
    priority:              :low,
    owner:                 admin,
    assignee:              nil,
    dev_estimate_hours:    16.0,
    tester_estimate_hours: 0.0,
    attach_spec:           true
  }
]

# Disable auto-branch-callback during seed to avoid noise
# (callback will still fire for the assigned ones — that's intentional)
created_ticket_count = 0
tickets_data.each do |t|
  ticket = Ticket.find_or_create_by!(project: t[:project], title: t[:title]) do |tk|
    tk.kind                  = t[:kind]
    tk.level                 = t[:level]        || :moderate
    tk.description           = t[:description]
    tk.status                = t[:status]
    tk.priority              = t[:priority]
    tk.owner                 = t[:owner]
    tk.assignee              = t[:assignee]
    tk.dev_estimate_hours    = t[:dev_estimate_hours]
    tk.tester_estimate_hours = t[:tester_estimate_hours]
    tk.how_to_reproduce      = t[:how_to_reproduce] if t[:how_to_reproduce]
    tk.pr_number             = t[:pr_number] if t[:pr_number]
    tk.pr_url                = t[:pr_url]    if t[:pr_url]
    created_ticket_count    += 1
  end

  # Always keep new fields up to date (idempotent on re-seed)
  ticket.update_columns(
    kind:  Ticket.kinds[t[:kind].to_s],
    level: Ticket.levels[(t[:level] || :moderate).to_s]
  )
  ticket.update_column(:how_to_reproduce, t[:how_to_reproduce]) if t[:how_to_reproduce].present?

  # Attach a spec/design document to feature and spike tickets (idempotent)
  next unless t[:attach_spec] && ticket.attachments.none?

  kind_label = t[:kind].to_s.capitalize
  spec_content = <<~MARKDOWN
    # #{kind_label.to_s.humanize} Specification: #{ticket.title}

    **Project:** #{ticket.project.name}
    **Kind:** #{kind_label.to_s.humanize.gsub("_", " ")}
    **Priority:** #{ticket.priority.capitalize}
    **Dev estimate:** #{t[:dev_estimate_hours]}h
    **QA estimate:** #{t[:tester_estimate_hours]}h

    ## Overview

    #{ticket.description}

    ## Acceptance Criteria

    - [ ] Implementation matches the described behaviour
    - [ ] Unit tests cover the main code paths
    - [ ] QA sign-off on the acceptance criteria
    - [ ] Documentation updated if applicable

    ## Technical Notes

    _To be filled in by the assigned developer._
  MARKDOWN

  ticket.attachments.attach(
    io:           StringIO.new(spec_content),
    filename:     "spec-T#{ticket.id}.md",
    content_type: "text/markdown"
  )
end

puts "  ✓ #{tickets_data.size} tickets (#{created_ticket_count} newly created)"
puts "  ✓ spec docs attached to feature/spike tickets"

puts "✅ Seed complete!"
