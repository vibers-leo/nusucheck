import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static targets = ["dropdown", "badge", "list", "count"]
  static values = {
    userId: Number,
    unreadCount: { type: Number, default: 0 }
  }

  connect() {
    this.consumer = createConsumer()
    this.subscribeToNotifications()
    this.updateBadge()
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }

  subscribeToNotifications() {
    this.subscription = this.consumer.subscriptions.create(
      { channel: "NotificationsChannel" },
      {
        received: (data) => {
          this.handleNewNotification(data)
        }
      }
    )
  }

  handleNewNotification(data) {
    // 리스트 상단에 알림 추가
    if (this.hasListTarget) {
      this.listTarget.insertAdjacentHTML('afterbegin', data.notification)
    }

    // 읽지 않은 알림 개수 증가
    this.unreadCountValue += 1
    this.updateBadge()

    // 토스트 알림 표시 (선택사항)
    this.showToast(data)
  }

  toggle(event) {
    event.preventDefault()
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
    // fixed 포지셔닝으로 stacking context 탈출
    dropdown.style.position = "fixed"
    dropdown.style.top = `${rect.bottom + 4}px`
    const rightOffset = window.innerWidth - rect.right
    dropdown.style.right = `${rightOffset}px`
    dropdown.style.left = "auto"
  }

  close(event) {
    if (!this.element.contains(event.target)) {
      this.dropdownTarget.classList.add("hidden")
    }
  }

  markAsRead(event) {
    const notificationId = event.currentTarget.dataset.notificationId
    const notificationElement = event.currentTarget.closest('[data-notification-id]')

    fetch(`/notifications/${notificationId}/mark_as_read`, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
        'Content-Type': 'application/json'
      }
    }).then(response => {
      if (response.ok) {
        notificationElement.classList.remove('bg-primary-50')
        notificationElement.classList.add('bg-white')
        this.unreadCountValue = Math.max(0, this.unreadCountValue - 1)
        this.updateBadge()
      }
    })
  }

  markAllAsRead(event) {
    event.preventDefault()

    fetch('/notifications/mark_all_as_read', {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
        'Content-Type': 'application/json'
      }
    }).then(response => {
      if (response.ok) {
        // 모든 알림 배경색 변경
        this.listTarget.querySelectorAll('[data-notification-id]').forEach(el => {
          el.classList.remove('bg-primary-50')
          el.classList.add('bg-white')
        })
        this.unreadCountValue = 0
        this.updateBadge()
      }
    })
  }

  updateBadge() {
    if (this.hasBadgeTarget) {
      if (this.unreadCountValue > 0) {
        this.badgeTarget.textContent = this.unreadCountValue > 99 ? '99+' : this.unreadCountValue
        this.badgeTarget.classList.remove('hidden')
      } else {
        this.badgeTarget.classList.add('hidden')
      }
    }

    if (this.hasCountTarget) {
      this.countTarget.textContent = this.unreadCountValue
    }
  }

  showToast(data) {
    // 간단한 토스트 알림 (선택사항)
    const toast = document.createElement('div')
    toast.className = 'fixed top-20 right-4 bg-white shadow-lg rounded-lg p-4 max-w-sm animate-slideIn z-50'
    toast.innerHTML = `
      <div class="flex items-start gap-3">
        <div class="text-2xl">${data.icon || '🔔'}</div>
        <div class="flex-1">
          <p class="font-semibold text-gray-900 text-sm">${data.title || '새 알림'}</p>
          <p class="text-gray-600 text-xs mt-1">${data.message || ''}</p>
        </div>
        <button onclick="this.parentElement.parentElement.remove()" class="text-gray-400 hover:text-gray-600">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
          </svg>
        </button>
      </div>
    `
    document.body.appendChild(toast)

    // 5초 후 자동 제거
    setTimeout(() => toast.remove(), 5000)
  }
}
