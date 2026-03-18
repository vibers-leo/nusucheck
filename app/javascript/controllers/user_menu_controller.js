import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropdown"]

  connect() {
    this.boundClose = this.closeIfOutside.bind(this)
    document.addEventListener("click", this.boundClose)
  }

  disconnect() {
    document.removeEventListener("click", this.boundClose)
  }

  toggle(event) {
    event.stopPropagation()
    const isHidden = this.dropdownTarget.classList.contains("hidden")
    if (isHidden) {
      this._positionDropdown(event.currentTarget)
      this.dropdownTarget.classList.remove("hidden")
    } else {
      this.dropdownTarget.classList.add("hidden")
    }
  }

  _positionDropdown(trigger) {
    const rect = trigger.getBoundingClientRect()
    const dropdown = this.dropdownTarget
    dropdown.style.position = "fixed"
    dropdown.style.top = `${rect.bottom + 4}px`
    dropdown.style.right = `${window.innerWidth - rect.right}px`
    dropdown.style.left = "auto"
  }

  closeIfOutside(event) {
    if (!this.element.contains(event.target)) {
      this.dropdownTarget.classList.add("hidden")
    }
  }
}
