import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "textarea"]

  connect() {
    this.boundClose = this.closeIfOutside.bind(this)
    document.addEventListener("click", this.boundClose)
  }

  disconnect() {
    document.removeEventListener("click", this.boundClose)
  }

  toggle(event) {
    event.stopPropagation()
    this.panelTarget.classList.toggle("hidden")
    if (!this.panelTarget.classList.contains("hidden")) {
      this.panelTarget.classList.add("flex", "flex-col")
    }
  }

  insert(event) {
    event.stopPropagation()
    const emoji = event.currentTarget.dataset.emoji
    const textarea = this.textareaTarget
    const start = textarea.selectionStart
    const end = textarea.selectionEnd
    const value = textarea.value
    textarea.value = value.substring(0, start) + emoji + value.substring(end)
    const newPos = start + emoji.length
    textarea.setSelectionRange(newPos, newPos)
    textarea.focus()
    // Dispatch input event to trigger resize
    textarea.dispatchEvent(new Event("input", { bubbles: true }))
    // Close panel after inserting
    this.panelTarget.classList.add("hidden")
  }

  closeIfOutside(event) {
    if (!this.element.contains(event.target)) {
      this.panelTarget.classList.add("hidden")
    }
  }
}
