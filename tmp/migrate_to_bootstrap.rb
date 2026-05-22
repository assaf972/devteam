#!/usr/bin/env ruby
# Bulma → Bootstrap 5 class migrator
# Processes all ERB files in app/views/

SUBS = [
  # ── Buttons (compound first) ──────────────────────────────────────────────
  ['button is-outlined is-primary',  'btn btn-outline-primary'],
  ['button is-outlined is-danger',   'btn btn-outline-danger'],
  ['button is-outlined is-success',  'btn btn-outline-success'],
  ['button is-outlined is-info',     'btn btn-outline-info'],
  ['button is-outlined is-warning',  'btn btn-outline-warning'],
  ['button is-primary is-outlined',  'btn btn-outline-primary'],
  ['button is-danger  is-outlined',  'btn btn-outline-danger'],
  ['button is-primary is-small',     'btn btn-primary btn-sm'],
  ['button is-danger  is-small',     'btn btn-danger btn-sm'],
  ['button is-success is-small',     'btn btn-success btn-sm'],
  ['button is-info    is-small',     'btn btn-info btn-sm'],
  ['button is-warning is-small',     'btn btn-warning btn-sm'],
  ['button is-dark    is-small',     'btn btn-dark btn-sm'],
  ['button is-light   is-small',     'btn btn-light btn-sm'],
  ['button is-link    is-small',     'btn btn-primary btn-sm'],
  ['button is-primary is-large',     'btn btn-primary btn-lg'],
  ['button is-primary',              'btn btn-primary'],
  ['button is-link',                 'btn btn-primary'],
  ['button is-success',              'btn btn-success'],
  ['button is-info is-light',        'btn btn-outline-info'],
  ['button is-info',                 'btn btn-info'],
  ['button is-warning',              'btn btn-warning'],
  ['button is-danger',               'btn btn-danger'],
  ['button is-dark',                 'btn btn-dark'],
  ['button is-light',                'btn btn-secondary'],
  ['button is-white',                'btn btn-light'],
  ['button is-text',                 'btn btn-link'],
  ['button is-ghost',                'btn btn-link'],
  ['button is-small',                'btn btn-secondary btn-sm'],
  ['button',                         'btn btn-secondary'],

  # ── Grid ──────────────────────────────────────────────────────────────────
  ['columns is-mobile',    'row'],
  ['columns is-desktop',   'row'],
  ['columns is-multiline', 'row'],
  ['columns is-gapless',   'row g-0'],
  ['columns is-centered',  'row justify-content-center'],
  ['columns is-vcentered', 'row align-items-center'],
  ['columns',              'row'],
  ['column is-12', 'col-12'], ['column is-11', 'col-11'], ['column is-10', 'col-10'],
  ['column is-9',  'col-9'],  ['column is-8',  'col-8'],  ['column is-7',  'col-7'],
  ['column is-6',  'col-6'],  ['column is-5',  'col-5'],  ['column is-4',  'col-4'],
  ['column is-3',  'col-3'],  ['column is-2',  'col-2'],  ['column is-1',  'col-1'],
  ['column is-half',           'col-6'],
  ['column is-one-third',      'col-4'],
  ['column is-two-thirds',     'col-8'],
  ['column is-one-quarter',    'col-3'],
  ['column is-three-quarters', 'col-9'],
  ['column is-narrow',         'col-auto'],
  ['column is-full',           'col-12'],
  ['column',                   'col'],

  # ── Tags / Badges ─────────────────────────────────────────────────────────
  ['tag is-rounded is-danger  is-light', 'badge rounded-pill bg-danger-subtle text-danger'],
  ['tag is-rounded is-success is-light', 'badge rounded-pill bg-success-subtle text-success'],
  ['tag is-rounded is-warning is-light', 'badge rounded-pill bg-warning-subtle text-warning-emphasis'],
  ['tag is-rounded is-info    is-light', 'badge rounded-pill bg-info-subtle text-info'],
  ['tag is-rounded is-primary is-light', 'badge rounded-pill bg-primary-subtle text-primary'],
  ['tag is-rounded is-danger',           'badge rounded-pill bg-danger'],
  ['tag is-rounded is-success',          'badge rounded-pill bg-success'],
  ['tag is-danger  is-light',  'badge bg-danger-subtle text-danger'],
  ['tag is-success is-light',  'badge bg-success-subtle text-success'],
  ['tag is-warning is-light',  'badge bg-warning-subtle text-warning-emphasis'],
  ['tag is-info    is-light',  'badge bg-info-subtle text-info'],
  ['tag is-primary is-light',  'badge bg-primary-subtle text-primary'],
  ['tag is-link    is-light',  'badge bg-primary-subtle text-primary'],
  ['tag is-dark    is-light',  'badge bg-secondary-subtle text-secondary'],
  ['tag is-white   is-light',  'badge bg-light text-dark'],
  ['tag is-light   is-small',  'badge bg-light text-dark'],
  ['tag is-light',             'badge bg-light text-dark'],
  ['tag is-success is-small',  'badge bg-success'],
  ['tag is-danger  is-small',  'badge bg-danger'],
  ['tag is-warning is-small',  'badge bg-warning text-dark'],
  ['tag is-info    is-small',  'badge bg-info'],
  ['tag is-primary is-small',  'badge bg-primary'],
  ['tag is-success',   'badge bg-success'],
  ['tag is-danger',    'badge bg-danger'],
  ['tag is-warning',   'badge bg-warning text-dark'],
  ['tag is-info',      'badge bg-info text-dark'],
  ['tag is-primary',   'badge bg-primary'],
  ['tag is-link',      'badge bg-primary'],
  ['tag is-dark',      'badge bg-dark'],
  ['tag is-black',     'badge bg-dark'],
  ['tag is-white',     'badge bg-light text-dark'],
  ['tag is-small',     'badge bg-secondary'],
  ['tag is-medium',    'badge bg-secondary'],
  ['tag is-rounded',   'badge rounded-pill bg-secondary'],
  ['tags',             'd-flex flex-wrap gap-1'],
  ['tag',              'badge bg-secondary'],

  # ── Notifications / Alerts ────────────────────────────────────────────────
  ['notification is-danger  is-light py-2 px-3', 'alert alert-danger py-2 px-3'],
  ['notification is-warning is-light py-2 px-3', 'alert alert-warning py-2 px-3'],
  ['notification is-danger  is-light', 'alert alert-danger'],
  ['notification is-warning is-light', 'alert alert-warning'],
  ['notification is-success is-light', 'alert alert-success'],
  ['notification is-info    is-light', 'alert alert-info'],
  ['notification is-primary is-light', 'alert alert-primary'],
  ['notification is-link    is-light', 'alert alert-primary'],
  ['notification is-danger',   'alert alert-danger'],
  ['notification is-warning',  'alert alert-warning'],
  ['notification is-success',  'alert alert-success'],
  ['notification is-info',     'alert alert-info'],
  ['notification is-primary',  'alert alert-primary'],
  ['notification is-light',    'alert alert-light'],
  ['notification',             'alert alert-secondary'],

  # ── Box / Card ───────────────────────────────────────────────────────────
  ['box has-background-warning-light', 'card p-3 bg-warning-subtle'],
  ['box has-background-danger-light',  'card p-3 bg-danger-subtle'],
  ['box has-background-success-light', 'card p-3 bg-success-subtle'],
  ['box has-background-info-light',    'card p-3 bg-info-subtle'],
  ['box has-background-light',         'card p-3 bg-light'],
  ['box mb-4', 'card p-3 mb-4'],
  ['box mb-3', 'card p-3 mb-3'],
  ['box mb-5', 'card p-3 mb-5'],
  ['box mb-6', 'card p-3 mb-5'],
  ['box p-3',  'card p-3'],
  ['box',      'card p-3 mb-3'],

  # ── Title ────────────────────────────────────────────────────────────────
  ['title is-1 mb-1', 'fw-bold fs-1 mb-1'], ['title is-1 mb-0', 'fw-bold fs-1 mb-0'],
  ['title is-2 mb-1', 'fw-bold fs-2 mb-1'], ['title is-2 mb-0', 'fw-bold fs-2 mb-0'],
  ['title is-3 mb-1', 'fw-bold fs-3 mb-1'], ['title is-3 mb-0', 'fw-bold fs-3 mb-0'],
  ['title is-4 mb-4', 'fw-bold fs-4 mb-4'], ['title is-4 mb-3', 'fw-bold fs-4 mb-3'],
  ['title is-4 mb-1', 'fw-bold fs-4 mb-1'], ['title is-4 mb-0', 'fw-bold fs-4 mb-0'],
  ['title is-5 mb-3', 'fw-bold fs-5 mb-3'], ['title is-5 mb-0', 'fw-bold fs-5 mb-0'],
  ['title is-6 mb-3', 'fw-bold fs-6 mb-3'], ['title is-6 mb-0', 'fw-bold fs-6 mb-0'],
  ['title is-1', 'fw-bold fs-1'], ['title is-2', 'fw-bold fs-2'],
  ['title is-3', 'fw-bold fs-3'], ['title is-4', 'fw-bold fs-4'],
  ['title is-5', 'fw-bold fs-5'], ['title is-6', 'fw-bold fs-6'],
  ['title mb-1', 'fw-bold mb-1'], ['title',       'fw-bold'],
  ['subtitle is-1', 'text-muted fs-1'], ['subtitle is-2', 'text-muted fs-2'],
  ['subtitle is-3', 'text-muted fs-3'], ['subtitle is-4', 'text-muted fs-4'],
  ['subtitle is-5', 'text-muted fs-5'], ['subtitle is-6', 'text-muted fs-6'],
  ['subtitle', 'text-muted'],

  # ── Form ─────────────────────────────────────────────────────────────────
  ['field is-grouped', 'd-flex gap-2 align-items-end'],
  ['field is-horizontal', 'row mb-3'],
  ['field',  'mb-3'],
  ['control is-expanded', 'flex-fill'],
  ['control', ''],
  ['help is-danger',  'form-text text-danger'],
  ['help is-success', 'form-text text-success'],
  ['help is-warning', 'form-text text-warning'],
  ['help is-info',    'form-text text-info'],
  ['help',            'form-text text-muted'],

  # ── Table ────────────────────────────────────────────────────────────────
  ['table is-fullwidth is-striped is-hoverable is-bordered', 'table table-striped table-hover table-bordered w-100'],
  ['table is-fullwidth is-striped is-hoverable',             'table table-striped table-hover w-100'],
  ['table is-fullwidth is-striped is-bordered',              'table table-striped table-bordered w-100'],
  ['table is-fullwidth is-hoverable is-bordered',            'table table-hover table-bordered w-100'],
  ['table is-fullwidth is-hoverable',                        'table table-hover w-100'],
  ['table is-fullwidth is-striped',                          'table table-striped w-100'],
  ['table is-fullwidth is-bordered',                         'table table-bordered w-100'],
  ['table is-fullwidth is-narrow',                           'table table-sm w-100'],
  ['table is-fullwidth',    'table w-100'],
  ['table is-striped is-hoverable', 'table table-striped table-hover'],
  ['table is-striped',   'table table-striped'],
  ['table is-hoverable', 'table table-hover'],
  ['table is-bordered',  'table table-bordered'],
  ['table is-narrow',    'table table-sm'],

  # ── Text Utilities ────────────────────────────────────────────────────────
  ['has-text-centered',       'text-center'],
  ['has-text-right',          'text-end'],
  ['has-text-left',           'text-start'],
  ['has-text-grey-dark',      'text-dark'],
  ['has-text-grey-light',     'text-muted'],
  ['has-text-grey',           'text-muted'],
  ['has-text-danger',         'text-danger'],
  ['has-text-success',        'text-success'],
  ['has-text-warning',        'text-warning'],
  ['has-text-info',           'text-info'],
  ['has-text-primary',        'text-primary'],
  ['has-text-link',           'text-primary'],
  ['has-text-white',          'text-white'],
  ['has-text-black',          'text-dark'],
  ['has-text-weight-bold',     'fw-bold'],
  ['has-text-weight-semibold', 'fw-semibold'],
  ['has-text-weight-medium',   'fw-medium'],
  ['has-text-weight-normal',   'fw-normal'],
  ['has-text-weight-light',    'fw-light'],

  # ── Background ───────────────────────────────────────────────────────────
  ['has-background-danger-light',  'bg-danger-subtle'],
  ['has-background-success-light', 'bg-success-subtle'],
  ['has-background-warning-light', 'bg-warning-subtle'],
  ['has-background-info-light',    'bg-info-subtle'],
  ['has-background-primary-light', 'bg-primary-subtle'],
  ['has-background-link-light',    'bg-primary-subtle'],
  ['has-background-white-bis',     'bg-light'],
  ['has-background-white',         'bg-white'],
  ['has-background-light',         'bg-light'],

  # ── Display / Flex ────────────────────────────────────────────────────────
  ['is-flex is-justify-content-space-between is-align-items-center', 'd-flex justify-content-between align-items-center'],
  ['is-flex is-justify-content-space-between', 'd-flex justify-content-between'],
  ['is-flex is-align-items-center',            'd-flex align-items-center'],
  ['is-flex',         'd-flex'],
  ['is-inline-flex',  'd-inline-flex'],
  ['is-block',        'd-block'],
  ['is-inline-block', 'd-inline-block'],
  ['is-inline',       'd-inline'],
  ['is-hidden',       'd-none'],
  ['is-invisible',    'invisible'],
  ['is-clipped',      'overflow-hidden'],
  ['is-pulled-left',  'float-start'],
  ['is-pulled-right', 'float-end'],
  ['is-fullwidth',    'w-100'],
  ['is-fullheight',   'h-100'],
  ['is-relative',     'position-relative'],

  # ── Flex alignment ───────────────────────────────────────────────────────
  ['is-justify-content-space-between', 'justify-content-between'],
  ['is-justify-content-space-around',  'justify-content-around'],
  ['is-justify-content-space-evenly',  'justify-content-evenly'],
  ['is-justify-content-center',        'justify-content-center'],
  ['is-justify-content-flex-end',      'justify-content-end'],
  ['is-justify-content-flex-start',    'justify-content-start'],
  ['is-align-items-baseline',   'align-items-baseline'],
  ['is-align-items-flex-start', 'align-items-start'],
  ['is-align-items-flex-end',   'align-items-end'],
  ['is-align-items-center',     'align-items-center'],
  ['is-align-items-stretch',    'align-items-stretch'],
  ['is-align-self-center',      'align-self-center'],
  ['is-align-self-flex-end',    'align-self-end'],
  ['is-align-self-flex-start',  'align-self-start'],
  ['is-flex-wrap-wrap',         'flex-wrap'],
  ['is-flex-wrap-nowrap',       'flex-nowrap'],
  ['is-flex-direction-column',  'flex-column'],
  ['is-flex-direction-row',     'flex-row'],

  # ── Spacing (l/r → s/e) ──────────────────────────────────────────────────
  ['ml-auto', 'ms-auto'], ['mr-auto', 'me-auto'],
  *[0,1,2,3,4,5,6].flat_map { |n|
    [["ml-#{n}", "ms-#{n}"], ["mr-#{n}", "me-#{n}"],
     ["pl-#{n}", "ps-#{n}"], ["pr-#{n}", "pe-#{n}"]]
  },

  # ── Size ─────────────────────────────────────────────────────────────────
  ['is-size-7', 'fs-7'],
  ['is-size-6', 'fs-6'],
  ['is-size-5', 'fs-5'],
  ['is-size-4', 'fs-4'],
  ['is-size-3', 'fs-3'],
  ['is-size-2', 'fs-2'],
  ['is-size-1', 'fs-1'],

  # ── Misc ─────────────────────────────────────────────────────────────────
  ['is-rounded',    'rounded'],
  ['is-radiusless', 'rounded-0'],
  ['is-loading',    ''],
  ['heading',       'text-uppercase text-muted fw-bold small'],
  ['delete',        'btn-close'],
  ['section',       'py-4'],

  # ── Navigation ───────────────────────────────────────────────────────────
  ['navbar is-primary',  'navbar navbar-expand-lg navbar-dark bg-primary'],
  ['navbar is-dark',     'navbar navbar-expand-lg navbar-dark bg-dark'],
  ['navbar is-light',    'navbar navbar-expand-lg navbar-light bg-light'],
  ['navbar is-white',    'navbar navbar-expand-lg navbar-light bg-white'],
  ['navbar is-info',     'navbar navbar-expand-lg navbar-dark bg-info'],
  ['navbar',             'navbar navbar-expand-lg navbar-dark bg-primary'],
  ['navbar-brand',       'navbar-brand'],
  ['navbar-burger',      'navbar-toggler'],
  ['navbar-menu',        'navbar-collapse collapse'],
  ['navbar-start',       'navbar-nav me-auto'],
  ['navbar-end',         'navbar-nav ms-auto'],
  ['navbar-item has-dropdown is-hoverable', 'nav-item dropdown'],
  ['navbar-item has-dropdown',              'nav-item dropdown'],
  ['navbar-dropdown is-right',              'dropdown-menu dropdown-menu-end'],
  ['navbar-dropdown',    'dropdown-menu'],
  ['navbar-link',        'nav-link dropdown-toggle'],
  ['navbar-item',        'nav-link'],

  # ── Tabs ─────────────────────────────────────────────────────────────────
  ['tabs is-boxed',    'nav nav-tabs'],
  ['tabs is-toggle',   'nav nav-pills'],
  ['tabs',             'nav nav-tabs'],

  # ── Modal ────────────────────────────────────────────────────────────────
  ['modal is-active',    'modal show d-block'],
  ['modal-background',   'modal-backdrop show'],
  ['modal-card',         'modal-dialog'],
  ['modal-card-head',    'modal-header'],
  ['modal-card-title',   'modal-title fw-bold'],
  ['modal-card-body',    'modal-body'],
  ['modal-card-foot',    'modal-footer'],
  ['modal-close',        'btn-close'],
  ['modal-content',      'modal-dialog'],
  ['modal',              'modal'],

  # ── Panel ────────────────────────────────────────────────────────────────
  ['panel-block',   'list-group-item'],
  ['panel-heading', 'card-header fw-bold'],
  ['panel',         'card mb-3'],
]

files = Dir.glob(File.join(__dir__, '..', 'app', 'views', '**', '*.erb'))
changed = 0
files.each do |f|
  original = File.read(f)
  content  = original.dup

  # Replace within class="..." and class: "..." attribute values
  content.gsub!(/(?:class:|class)(?:\s*=\s*|\s+)("(?:[^"\\]|\\.)*")/) do |match|
    quote = $1
    inner = quote[1..-2]  # strip surrounding quotes
    SUBS.each do |from, to|
      inner = inner.gsub(from, to)
    end
    match.sub(quote, "\"#{inner}\"")
  end

  if content != original
    File.write(f, content)
    changed += 1
    puts "  updated: #{f.sub(%r{.*/app/views/}, 'app/views/')}"
  end
end
puts "Done. #{changed}/#{files.size} files updated."
