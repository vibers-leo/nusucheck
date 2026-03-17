import { Controller } from "@hotwired/stimulus"

const MAX_SIZE_BYTES = 100 * 1024 * 1024 // 100MB

export default class extends Controller {
  static targets = ["dropzone", "input", "preview", "videoPreview", "placeholder", "submitBtn", "fileInfo"]

  trigger(event) {
    // input의 click 이벤트가 버블링되어 다시 trigger 되는 것 방지
    if (event && event.target === this.inputTarget) return
    this.inputTarget.click()
  }

  keydown(event) {
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault()
      this.trigger()
    }
  }

  preview() {
    const file = this.inputTarget.files[0]
    if (!file) return

    if (file.size > MAX_SIZE_BYTES) {
      alert(`파일 크기는 100MB를 초과할 수 없습니다.\n현재 파일: ${this._formatSize(file.size)}`)
      this.inputTarget.value = ""
      return
    }

    const isVideo = file.type.startsWith("video/")
    const isImage = file.type.startsWith("image/")

    if (!isVideo && !isImage) {
      alert("이미지 또는 영상 파일만 업로드할 수 있습니다.")
      this.inputTarget.value = ""
      return
    }

    this.placeholderTarget.classList.add("hidden")

    if (isVideo) {
      this._showVideoPreview(file)
    } else {
      this._showImagePreview(file)
    }

    if (this.hasSubmitBtnTarget) {
      this.submitBtnTarget.disabled = false
      this.submitBtnTarget.classList.remove("opacity-50", "cursor-not-allowed")
    }
  }

  dragover(event) {
    event.preventDefault()
    event.stopPropagation()
    this.dropzoneTarget.classList.add("border-primary-400", "bg-primary-50", "scale-[1.01]")
  }

  dragleave(event) {
    event.preventDefault()
    // 자식 요소로 이동할 때 dragleave 무시
    if (this.dropzoneTarget.contains(event.relatedTarget)) return
    this.dropzoneTarget.classList.remove("border-primary-400", "bg-primary-50", "scale-[1.01]")
  }

  drop(event) {
    event.preventDefault()
    event.stopPropagation()
    this.dropzoneTarget.classList.remove("border-primary-400", "bg-primary-50", "scale-[1.01]")

    const files = event.dataTransfer.files
    if (files.length > 0) {
      this.inputTarget.files = files
      this.preview()
    }
  }

  _showVideoPreview(file) {
    if (this.hasPreviewTarget) this.previewTarget.classList.add("hidden")

    if (this.hasVideoPreviewTarget) {
      const url = URL.createObjectURL(file)
      this.videoPreviewTarget.src = url
      this.videoPreviewTarget.classList.remove("hidden")
    }

    if (this.hasFileInfoTarget) {
      this.fileInfoTarget.innerHTML = `
        <div class="flex items-center gap-2 text-sm text-gray-600">
          <svg class="w-5 h-5 text-primary-500 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"/>
          </svg>
          <span class="font-medium truncate max-w-xs">${file.name}</span>
          <span class="text-gray-400 flex-shrink-0">${this._formatSize(file.size)}</span>
          <span class="px-2 py-0.5 bg-purple-100 text-purple-700 text-xs font-bold rounded-full flex-shrink-0">영상</span>
        </div>
        <p class="text-xs text-gray-400 mt-1">업로드 후 자동으로 최적화됩니다 ✨</p>
      `
      this.fileInfoTarget.classList.remove("hidden")
    }
  }

  _showImagePreview(file) {
    if (this.hasVideoPreviewTarget) this.videoPreviewTarget.classList.add("hidden")

    if (this.hasPreviewTarget) {
      const reader = new FileReader()
      reader.onload = (e) => {
        this.previewTarget.src = e.target.result
        this.previewTarget.classList.remove("hidden")
        this.previewTarget.setAttribute("alt", file.name)
      }
      reader.readAsDataURL(file)
    }

    if (this.hasFileInfoTarget) {
      this.fileInfoTarget.innerHTML = `
        <div class="flex items-center gap-2 text-sm text-gray-600">
          <svg class="w-5 h-5 text-green-500 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z"/>
          </svg>
          <span class="font-medium truncate max-w-xs">${file.name}</span>
          <span class="text-gray-400 flex-shrink-0">${this._formatSize(file.size)}</span>
          <span class="px-2 py-0.5 bg-green-100 text-green-700 text-xs font-bold rounded-full flex-shrink-0">사진</span>
        </div>
      `
      this.fileInfoTarget.classList.remove("hidden")
    }
  }

  _formatSize(bytes) {
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)}KB`
    return `${(bytes / (1024 * 1024)).toFixed(1)}MB`
  }
}
