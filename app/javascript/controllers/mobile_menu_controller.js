import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "button", "iconOpen", "iconClose"]

  connect() {
    this.isOpen = false
    this._onKeydown = this._onKeydown.bind(this)
    this._onTurboNav = this.close.bind(this)
    this._onOutsideClick = this._onOutsideClick.bind(this)
    document.addEventListener("keydown", this._onKeydown)
    document.addEventListener("turbo:before-visit", this._onTurboNav)
  }

  disconnect() {
    document.removeEventListener("keydown", this._onKeydown)
    document.removeEventListener("turbo:before-visit", this._onTurboNav)
    document.body.style.overflow = ""
  }

  toggle(event) {
    event.stopPropagation()
    this.isOpen ? this.close() : this.open()
  }

  open() {
    this.isOpen = true
    if (this.hasPanelTarget) {
      this.panelTarget.classList.remove("hidden")
      this.panelTarget.style.display = "block"
    }
    if (this.hasIconOpenTarget) this.iconOpenTarget.classList.add("hidden")
    if (this.hasIconCloseTarget) this.iconCloseTarget.classList.remove("hidden")
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-expanded", "true")
      this.buttonTarget.setAttribute("aria-label", "메뉴 닫기")
    }
    document.body.style.overflow = "hidden"
    // 패널 외부 클릭 시 닫기 (딜레이로 open 클릭이 바로 close로 이어지는 것 방지)
    setTimeout(() => {
      document.addEventListener("click", this._onOutsideClick)
    }, 100)
  }

  close() {
    if (!this.isOpen) return
    this.isOpen = false
    if (this.hasPanelTarget) {
      this.panelTarget.classList.add("hidden")
      this.panelTarget.style.display = ""
    }
    if (this.hasIconOpenTarget) this.iconOpenTarget.classList.remove("hidden")
    if (this.hasIconCloseTarget) this.iconCloseTarget.classList.add("hidden")
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-expanded", "false")
      this.buttonTarget.setAttribute("aria-label", "메뉴 열기")
    }
    document.body.style.overflow = ""
    document.removeEventListener("click", this._onOutsideClick)
  }

  _onOutsideClick(event) {
    if (this.hasPanelTarget && !this.panelTarget.contains(event.target) &&
        this.hasButtonTarget && !this.buttonTarget.contains(event.target)) {
      this.close()
    }
  }

  _onKeydown(event) {
    if (event.key === "Escape" && this.isOpen) {
      this.close()
    }
  }
}
