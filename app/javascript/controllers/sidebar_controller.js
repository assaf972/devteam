import { Controller } from "@hotwired/stimulus"

// Handles collapsible project sections + panel toggle in the sidebar
export default class extends Controller {
    static targets = ["project", "panel"]

    toggleProject(event) {
        const header = event.currentTarget
        const project = header.closest(".sidebar-project")
        if (project) project.classList.toggle("is-open")
    }

    togglePanel() {
        const panel = document.getElementById("rightPanel")
        if (panel) {
            panel.classList.toggle("is-hidden")
            this.element.querySelector(".topbar-panel-toggle")?.classList.toggle("is-active")
        }
    }
}
