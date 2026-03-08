import { Controller } from "@hotwired/stimulus"

// 영상 압축 컨트롤러
// MediaRecorder API를 사용한 클라이언트 사이드 영상 압축
export default class extends Controller {
  static targets = [
    "input",
    "compressionModal",
    "compressionProgress",
    "compressionText",
    "currentFile",
    "totalFiles",
    "skipButton",
    "statusMessage"
  ]

  static values = {
    maxSizeMb: { type: Number, default: 50 },      // 압축 시작 임계값 (MB)
    targetBitrate: { type: Number, default: 1500 }, // 목표 비트레이트 (kbps)
    enabled: { type: Boolean, default: true }
  }

  connect() {
    this.compressing = false
    this.shouldCompress = false

    // 파일 선택 이벤트 리스너
    if (this.hasInputTarget) {
      this.inputTarget.addEventListener("change", this.handleFileChange.bind(this))
    }
  }

  disconnect() {
    // 압축 중단
    if (this.compressing) {
      this.cancelCompression()
    }
  }

  // 파일 변경 핸들러
  async handleFileChange(event) {
    if (!this.enabledValue) return

    const files = Array.from(event.target.files)
    if (files.length === 0) return

    // 압축이 필요한 파일 필터링
    const filesToCompress = files.filter(file => {
      const fileSizeMB = file.size / (1024 * 1024)
      return fileSizeMB > this.maxSizeMbValue
    })

    if (filesToCompress.length === 0) {
      console.log("All files are under threshold, no compression needed")
      return
    }

    // 압축 시작
    await this.compressFiles(files, filesToCompress)
  }

  // 파일 압축 시작
  async compressFiles(allFiles, filesToCompress) {
    this.compressing = true

    // 압축 모달 표시
    this.showCompressionModal(filesToCompress.length)

    const compressedFiles = []
    const skippedFiles = []

    for (let i = 0; i < allFiles.length; i++) {
      const file = allFiles[i]
      const shouldCompressThisFile = filesToCompress.includes(file)

      // 현재 파일 정보 업데이트
      this.updateProgress(i + 1, allFiles.length, file.name)

      if (shouldCompressThisFile) {
        try {
          console.log(`Compressing file ${i + 1}/${allFiles.length}: ${file.name}`)

          const compressed = await this.compressVideo(file)

          if (compressed) {
            compressedFiles.push({ original: file, compressed: compressed })
            this.showStatus(`✅ ${file.name} 압축 완료 (${this.formatFileSize(file.size)} → ${this.formatFileSize(compressed.size)})`)
          } else {
            skippedFiles.push(file)
            this.showStatus(`⚠️ ${file.name} 압축 실패, 원본 사용`)
          }
        } catch (error) {
          console.error("Compression error:", error)
          skippedFiles.push(file)
          this.showStatus(`⚠️ ${file.name} 압축 실패, 원본 사용`)

          // Sentry: 압축 에러 추적
          this.element.dispatchEvent(new CustomEvent("sentry:error", {
            detail: {
              error: error,
              context: {
                error_type: "video_compression_error",
                file_name: file.name,
                file_size: file.size
              }
            },
            bubbles: true
          }))
        }
      } else {
        // 압축 불필요 파일은 그대로 유지
        skippedFiles.push(file)
      }

      // 짧은 딜레이 (UI 업데이트 시간)
      await this.delay(100)
    }

    // 압축된 파일로 input 업데이트
    if (compressedFiles.length > 0) {
      this.updateFileInput(compressedFiles, skippedFiles)
    }

    // Analytics: 압축 완료 이벤트
    this.dispatchAnalyticsEvent("video_compression_completed", {
      total_files: allFiles.length,
      compressed_count: compressedFiles.length,
      skipped_count: skippedFiles.length,
      total_size_saved_mb: this.calculateSizeSaved(compressedFiles)
    })

    // 압축 완료 메시지
    this.showCompletionMessage(compressedFiles.length)

    // 2초 후 모달 닫기
    await this.delay(2000)
    this.hideCompressionModal()

    this.compressing = false
  }

  // 영상 압축 (MediaRecorder API 사용)
  async compressVideo(file) {
    return new Promise((resolve, reject) => {
      const video = document.createElement("video")
      video.preload = "metadata"

      video.onloadedmetadata = async () => {
        try {
          // 비디오를 canvas에 그리기 위한 설정
          const canvas = document.createElement("canvas")
          const ctx = canvas.getContext("2d")

          // 압축 목표: 720p 또는 원본 해상도 중 작은 것
          const maxWidth = 1280
          const maxHeight = 720
          let width = video.videoWidth
          let height = video.videoHeight

          // 비율 유지하면서 리사이징
          if (width > maxWidth || height > maxHeight) {
            const aspectRatio = width / height
            if (width > height) {
              width = maxWidth
              height = Math.round(width / aspectRatio)
            } else {
              height = maxHeight
              width = Math.round(height * aspectRatio)
            }
          }

          canvas.width = width
          canvas.height = height

          // MediaStream 생성 (canvas → stream)
          const stream = canvas.captureStream(30) // 30 FPS

          // MediaRecorder 설정
          const mimeType = this.getSupportedMimeType()
          const options = {
            mimeType: mimeType,
            videoBitsPerSecond: this.targetBitrateValue * 1000 // kbps to bps
          }

          const mediaRecorder = new MediaRecorder(stream, options)
          const chunks = []

          mediaRecorder.ondataavailable = (e) => {
            if (e.data.size > 0) {
              chunks.push(e.data)
            }
          }

          mediaRecorder.onstop = () => {
            const compressedBlob = new Blob(chunks, { type: mimeType })
            const compressedFile = new File(
              [compressedBlob],
              file.name.replace(/\.[^/.]+$/, "_compressed.mp4"),
              { type: mimeType, lastModified: Date.now() }
            )

            // 압축 효과 확인 (압축 후가 더 크면 원본 사용)
            if (compressedFile.size < file.size) {
              resolve(compressedFile)
            } else {
              console.log("Compressed file is larger, using original")
              resolve(null)
            }
          }

          mediaRecorder.onerror = (error) => {
            console.error("MediaRecorder error:", error)
            reject(error)
          }

          // 녹화 시작
          mediaRecorder.start()

          // 비디오 재생 및 canvas에 그리기
          video.currentTime = 0
          video.play()

          const drawFrame = () => {
            if (video.paused || video.ended) {
              mediaRecorder.stop()
              URL.revokeObjectURL(video.src)
              return
            }

            ctx.drawImage(video, 0, 0, width, height)
            requestAnimationFrame(drawFrame)
          }

          video.onplay = () => {
            drawFrame()
          }

          // 재생 종료 시 녹화 중지
          video.onended = () => {
            mediaRecorder.stop()
          }

        } catch (error) {
          console.error("Video processing error:", error)
          reject(error)
        }
      }

      video.onerror = (error) => {
        console.error("Video loading error:", error)
        reject(error)
      }

      // 비디오 로드
      video.src = URL.createObjectURL(file)
    })
  }

  // 지원되는 MIME 타입 확인
  getSupportedMimeType() {
    const types = [
      "video/webm;codecs=vp9",
      "video/webm;codecs=vp8",
      "video/webm",
      "video/mp4"
    ]

    for (const type of types) {
      if (MediaRecorder.isTypeSupported(type)) {
        return type
      }
    }

    return "video/webm" // 기본값
  }

  // 파일 입력 업데이트
  updateFileInput(compressedFiles, skippedFiles) {
    const dataTransfer = new DataTransfer()

    // 압축된 파일 추가
    compressedFiles.forEach(({ compressed }) => {
      dataTransfer.items.add(compressed)
    })

    // 압축하지 않은 파일 추가
    skippedFiles.forEach(file => {
      dataTransfer.items.add(file)
    })

    // input 업데이트
    this.inputTarget.files = dataTransfer.files

    // change 이벤트 발생 (file-counter 등 다른 컨트롤러 업데이트)
    this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
  }

  // 압축 모달 표시
  showCompressionModal(totalFiles) {
    if (this.hasCompressionModalTarget) {
      this.compressionModalTarget.classList.remove("hidden")
      this.compressionModalTarget.classList.add("flex")
    }

    if (this.hasTotalFilesTarget) {
      this.totalFilesTarget.textContent = totalFiles
    }
  }

  // 압축 모달 숨김
  hideCompressionModal() {
    if (this.hasCompressionModalTarget) {
      this.compressionModalTarget.classList.add("hidden")
      this.compressionModalTarget.classList.remove("flex")
    }
  }

  // 진행률 업데이트
  updateProgress(current, total, fileName) {
    const percent = Math.round((current / total) * 100)

    if (this.hasCompressionProgressTarget) {
      this.compressionProgressTarget.style.width = `${percent}%`
    }

    if (this.hasCompressionTextTarget) {
      this.compressionTextTarget.textContent = `${percent}%`
    }

    if (this.hasCurrentFileTarget) {
      this.currentFileTarget.textContent = current
    }

    if (this.hasCurrentFileTarget && fileName) {
      this.showStatus(`🔄 ${fileName} 압축 중...`)
    }
  }

  // 상태 메시지 표시
  showStatus(message) {
    if (this.hasStatusMessageTarget) {
      this.statusMessageTarget.textContent = message
    }
    console.log(message)
  }

  // 완료 메시지
  showCompletionMessage(compressedCount) {
    this.showStatus(`✅ ${compressedCount}개 영상 압축 완료!`)

    if (this.hasCompressionTextTarget) {
      this.compressionTextTarget.textContent = "완료!"
      this.compressionTextTarget.classList.add("text-green-600")
    }
  }

  // 압축 건너뛰기
  skip(event) {
    event.preventDefault()

    if (confirm("영상 압축을 건너뛰시겠습니까?\n원본 파일 그대로 업로드됩니다.")) {
      this.cancelCompression()

      // Analytics: 압축 건너뛰기 이벤트
      this.dispatchAnalyticsEvent("video_compression_skipped", {})
    }
  }

  // 압축 취소
  cancelCompression() {
    this.compressing = false
    this.hideCompressionModal()
  }

  // 절약된 용량 계산
  calculateSizeSaved(compressedFiles) {
    let saved = 0
    compressedFiles.forEach(({ original, compressed }) => {
      saved += original.size - compressed.size
    })
    return Math.round(saved / (1024 * 1024) * 100) / 100 // MB
  }

  // 파일 크기 포맷팅
  formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes'

    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))

    return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i]
  }

  // 딜레이 헬퍼
  delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms))
  }

  // Analytics 이벤트 발생
  dispatchAnalyticsEvent(eventName, params) {
    this.element.dispatchEvent(new CustomEvent("analytics:custom", {
      detail: {
        event_name: eventName,
        params: params
      },
      bubbles: true
    }))
  }
}
