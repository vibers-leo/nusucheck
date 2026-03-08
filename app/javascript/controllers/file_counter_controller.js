import { Controller } from "@hotwired/stimulus"

// 파일 업로드 카운터 컨트롤러 (영상만, 당근마켓 스타일)
export default class extends Controller {
  static targets = ["videoInput", "videoCount"]
  static values = {
    videoMax: { type: Number, default: 10 }
  }

  connect() {
    this.updateVideoCounts()
  }

  updateVideoCounts() {
    if (!this.hasVideoInputTarget || !this.hasVideoCountTarget) return

    const count = this.videoInputTarget.files.length

    if (count > 0) {
      this.videoCountTarget.innerHTML = `
        <div class="inline-flex items-center gap-2 px-4 py-2 bg-primary-100 text-primary-700 rounded-full">
          <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
            <path d="M2 6a2 2 0 012-2h6a2 2 0 012 2v8a2 2 0 01-2 2H4a2 2 0 01-2-2V6zM14.553 7.106A1 1 0 0014 8v4a1 1 0 00.553.894l2 1A1 1 0 0018 13V7a1 1 0 00-1.447-.894l-2 1z"/>
          </svg>
          <span class="font-bold">${count}개 영상 선택됨</span>
        </div>
      `
    } else {
      this.videoCountTarget.textContent = ''
    }
  }
}
