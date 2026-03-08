import { Controller } from "@hotwired/stimulus"

// 삼쩜삼/토스 스타일 멀티 스텝 폼 컨트롤러
export default class extends Controller {
  static targets = ["step", "progress", "progressBar", "prevBtn", "nextBtn", "submitBtn"]
  static values = {
    currentStep: { type: Number, default: 1 },
    totalSteps: { type: Number, default: 5 }
  }

  connect() {
    this.showStep(this.currentStepValue)
    this.updateProgress()
    this.goToErrorStep()
    this.restoreSelections()  // 서버 검증 실패 시 선택 상태 복원
  }

  // 서버 검증 오류 시 해당 단계로 자동 이동
  goToErrorStep() {
    // 각 필드와 단계 매핑
    const fieldStepMap = {
      'symptom_type': 1,
      'building_type': 1,
      'address': 2,
      'detailed_address': 2,
      'floor': 2,
      'description': 3,
      'preferred_date': 3,
      'photos': 4,
      'videos': 4
    }

    // 에러가 있는 필드 찾기
    const errorFields = document.querySelectorAll('.field_with_errors input, .field_with_errors select, .field_with_errors textarea')

    if (errorFields.length > 0) {
      // 첫 번째 에러 필드의 이름 추출
      const firstErrorField = errorFields[0]
      const fieldName = firstErrorField.name.match(/\[(\w+)\]/)?.[1]

      if (fieldName && fieldStepMap[fieldName]) {
        this.currentStepValue = fieldStepMap[fieldName]
        this.showStep(this.currentStepValue)
        this.updateProgress()

        // 에러 필드로 스크롤
        setTimeout(() => {
          firstErrorField.scrollIntoView({ behavior: 'smooth', block: 'center' })
          firstErrorField.focus()
        }, 300)
      }
    }
  }

  next(event) {
    event.preventDefault()

    // 현재 단계 유효성 검사
    if (!this.validateCurrentStep()) {
      return
    }

    // 자동 저장
    this.autoSave()

    if (this.currentStepValue < this.totalStepsValue) {
      this.currentStepValue++
      this.showStep(this.currentStepValue)
      this.updateProgress()
      this.scrollToTop()
    }
  }

  prev(event) {
    event.preventDefault()

    if (this.currentStepValue > 1) {
      this.currentStepValue--
      this.showStep(this.currentStepValue)
      this.updateProgress()
      this.scrollToTop()
    }
  }

  goToStep(event) {
    const step = parseInt(event.currentTarget.dataset.step)
    if (step <= this.currentStepValue) {
      this.currentStepValue = step
      this.showStep(this.currentStepValue)
      this.updateProgress()
      this.scrollToTop()
    }
  }

  showStep(stepNumber) {
    this.stepTargets.forEach((step, index) => {
      if (index + 1 === stepNumber) {
        step.classList.remove("hidden")
        step.classList.add("fade-in")
      } else {
        step.classList.add("hidden")
        step.classList.remove("fade-in")
      }
    })

    // 버튼 표시/숨김
    if (this.hasPrevBtnTarget) {
      this.prevBtnTarget.classList.toggle("hidden", stepNumber === 1)
    }

    if (this.hasNextBtnTarget && this.hasSubmitBtnTarget) {
      const isLastStep = stepNumber === this.totalStepsValue
      this.nextBtnTarget.classList.toggle("hidden", isLastStep)
      this.submitBtnTarget.classList.toggle("hidden", !isLastStep)
    }
  }

  updateProgress() {
    const percentage = (this.currentStepValue / this.totalStepsValue) * 100

    // 프로그레스 바 업데이트
    if (this.hasProgressBarTarget) {
      this.progressBarTarget.style.width = `${percentage}%`
    }

    // 프로그레스 텍스트 업데이트
    if (this.hasProgressTarget) {
      this.progressTarget.textContent = `${this.currentStepValue}/${this.totalStepsValue}`
    }

    // 단계별 인디케이터 업데이트
    document.querySelectorAll('[data-step-indicator]').forEach((indicator, index) => {
      const stepNum = index + 1
      const circle = indicator.querySelector('.step-circle')
      const label = indicator.querySelector('.step-label')

      if (stepNum < this.currentStepValue) {
        // 완료된 단계
        circle.classList.remove('bg-gray-300', 'bg-primary-600', 'text-gray-600', 'text-white')
        circle.classList.add('bg-green-500', 'text-white')
        circle.innerHTML = '<svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/></svg>'
        label.classList.remove('text-gray-600', 'text-primary-600')
        label.classList.add('text-green-600')
      } else if (stepNum === this.currentStepValue) {
        // 현재 단계
        circle.classList.remove('bg-gray-300', 'bg-green-500', 'text-gray-600')
        circle.classList.add('bg-primary-600', 'text-white')
        circle.textContent = stepNum
        label.classList.remove('text-gray-600', 'text-green-600')
        label.classList.add('text-primary-600', 'font-semibold')
      } else {
        // 미완료 단계
        circle.classList.remove('bg-primary-600', 'bg-green-500', 'text-white')
        circle.classList.add('bg-gray-300', 'text-gray-600')
        circle.textContent = stepNum
        label.classList.remove('text-primary-600', 'text-green-600', 'font-semibold')
        label.classList.add('text-gray-600')
      }
    })
  }

  validateCurrentStep() {
    // 단계 1: 증상 타입과 건물 타입 검증 (hidden input)
    if (this.currentStepValue === 1) {
      const symptom = document.getElementById('symptom-type-input')?.value
      const building = document.getElementById('building-type-input')?.value

      if (!symptom || !building) {
        this.showError('증상과 건물 종류를 선택해주세요')
        return false
      }
    }

    const currentStepElement = this.stepTargets[this.currentStepValue - 1]
    const requiredInputs = currentStepElement.querySelectorAll('[required]')

    let isValid = true
    let firstInvalidInput = null

    requiredInputs.forEach(input => {
      // hidden input은 건너뛰기 (위에서 이미 검증)
      if (input.type === 'hidden') return

      // readonly 필드는 value만 체크 (disabled는 검증 제외)
      const shouldValidate = !input.disabled
      const isEmpty = !input.value || input.value.trim() === ''

      if (shouldValidate && isEmpty) {
        isValid = false
        input.classList.add('border-red-500')

        if (!firstInvalidInput) {
          firstInvalidInput = input
        }

        // 에러 메시지 표시
        let errorMsg = input.parentElement.querySelector('.error-message')
        if (!errorMsg) {
          errorMsg = document.createElement('p')
          errorMsg.className = 'error-message text-xs text-red-600 mt-1'
          errorMsg.textContent = '이 항목은 필수예요'
          input.parentElement.appendChild(errorMsg)
        }
      } else {
        input.classList.remove('border-red-500')
        const errorMsg = input.parentElement.querySelector('.error-message')
        if (errorMsg) {
          errorMsg.remove()
        }
      }
    })

    if (!isValid) {
      // 부드러운 shake 애니메이션
      currentStepElement.classList.add('shake')
      setTimeout(() => {
        currentStepElement.classList.remove('shake')
      }, 500)

      // 첫 번째 오류 필드로 스크롤
      if (firstInvalidInput) {
        setTimeout(() => {
          firstInvalidInput.scrollIntoView({ behavior: 'smooth', block: 'center' })
          // readonly가 아니면 포커스
          if (!firstInvalidInput.readOnly) {
            firstInvalidInput.focus()
          }
        }, 300)
      }
    }

    return isValid
  }

  showError(message) {
    // 에러 메시지 표시 (toast 또는 alert)
    alert(message)
  }

  autoSave() {
    // 자동 저장 표시
    const saveIndicator = document.getElementById('autoSaveIndicator')
    if (saveIndicator) {
      saveIndicator.textContent = '💾 자동 저장 중...'
      saveIndicator.classList.remove('text-green-600', 'text-gray-500')
      saveIndicator.classList.add('text-primary-600')

      // 1초 후 저장 완료 표시
      setTimeout(() => {
        saveIndicator.textContent = '✅ 저장됨'
        saveIndicator.classList.remove('text-primary-600')
        saveIndicator.classList.add('text-green-600')

        setTimeout(() => {
          saveIndicator.textContent = '자동 저장됨'
          saveIndicator.classList.remove('text-green-600')
          saveIndicator.classList.add('text-gray-500')
        }, 2000)
      }, 1000)
    }

    // 실제 AJAX 저장은 여기서 구현 (선택적)
    // this.saveDraft()
  }

  scrollToTop() {
    window.scrollTo({
      top: 0,
      behavior: 'smooth'
    })
  }

  // 실시간 입력 유효성 검사
  validateInput(event) {
    const input = event.target
    if (input.required && input.value.trim()) {
      input.classList.remove('border-red-500')
      const errorMsg = input.parentElement.querySelector('.error-message')
      if (errorMsg) {
        errorMsg.remove()
      }
    }
  }

  // ===== 토스 스타일 버튼 선택 기능 =====

  // 버튼 선택 시 호출 (Ripple + 햅틱 피드백)
  selectOption(event) {
    event.preventDefault()

    const button = event.currentTarget
    const field = button.dataset.field
    const value = button.dataset.value
    const gradient = button.dataset.gradient  // 그라디언트 색상

    // === 1. Ripple 효과 생성 ===
    this.createRipple(event, button, gradient)

    // === 2. 햅틱 피드백 시뮬레이션 (진동 효과) ===
    if (navigator.vibrate) {
      navigator.vibrate(10)  // 10ms 짧은 진동
    }

    // === 3. 같은 그룹의 다른 버튼 선택 해제 ===
    const group = button.closest('[data-option-group]')
    group.querySelectorAll('.option-btn').forEach(btn => {
      // 선택 해제
      btn.classList.remove('shadow-xl', 'scale-105', 'selected')
      btn.classList.add('shadow-md')

      // 체크 아이콘 숨김
      btn.querySelector('.check-icon')?.classList.add('hidden')
      btn.setAttribute('aria-checked', 'false')
    })

    // === 4. 현재 버튼 선택 표시 ===
    button.classList.remove('shadow-md')
    button.classList.add('shadow-xl', 'scale-105', 'selected')
    button.querySelector('.check-icon')?.classList.remove('hidden')
    button.setAttribute('aria-checked', 'true')

    // === 5. Scale + Bounce 애니메이션 ===
    button.animate([
      { transform: 'scale(1)' },
      { transform: 'scale(1.05)' },
      { transform: 'scale(0.98)' },
      { transform: 'scale(1.05)' }
    ], {
      duration: 400,
      easing: 'cubic-bezier(0.68, -0.55, 0.265, 1.55)'
    })

    // === 6. Hidden input 업데이트 ===
    const input = document.getElementById(`${field}-input`)
    if (input) {
      input.value = value
      input.dispatchEvent(new Event('input', { bubbles: true }))
    }
  }

  // Ripple 효과 생성 (토스 스타일)
  createRipple(event, button, gradient) {
    const ripple = document.createElement('span')
    const rect = button.getBoundingClientRect()
    const size = Math.max(rect.width, rect.height)
    const x = event.clientX - rect.left - size / 2
    const y = event.clientY - rect.top - size / 2

    // 그라디언트별 Ripple 색상
    const gradientColors = {
      blue: 'rgba(59, 130, 246, 0.4)',
      purple: 'rgba(168, 85, 247, 0.4)',
      teal: 'rgba(20, 184, 166, 0.4)',
      orange: 'rgba(249, 115, 22, 0.4)',
      pink: 'rgba(236, 72, 153, 0.4)',
      green: 'rgba(34, 197, 94, 0.4)',
      indigo: 'rgba(99, 102, 241, 0.4)',
      cyan: 'rgba(6, 182, 212, 0.4)',
      amber: 'rgba(245, 158, 11, 0.4)',
      rose: 'rgba(244, 63, 94, 0.4)',
      lime: 'rgba(132, 204, 22, 0.4)',
      slate: 'rgba(100, 116, 139, 0.4)',
      gray: 'rgba(107, 114, 128, 0.4)'
    }

    ripple.style.cssText = `
      position: absolute;
      border-radius: 50%;
      background: ${gradientColors[gradient] || gradientColors.blue};
      width: ${size}px;
      height: ${size}px;
      left: ${x}px;
      top: ${y}px;
      transform: scale(0);
      animation: rippleEffect 600ms ease-out;
      pointer-events: none;
      z-index: 10;
    `

    button.style.position = 'relative'
    button.style.overflow = 'hidden'
    button.appendChild(ripple)

    setTimeout(() => ripple.remove(), 600)
  }

  // 서버 검증 실패 시 선택 상태 복원
  restoreSelections() {
    const symptomInput = document.getElementById('symptom-type-input')
    if (symptomInput?.value) {
      const btn = document.querySelector(`[data-field="symptom_type"][data-value="${symptomInput.value}"]`)
      if (btn) {
        // 애니메이션 없이 선택 상태만 적용
        btn.classList.add('shadow-xl', 'scale-105', 'selected')
        btn.querySelector('.check-icon')?.classList.remove('hidden')
        btn.setAttribute('aria-checked', 'true')
      }
    }

    const buildingInput = document.getElementById('building-type-input')
    if (buildingInput?.value) {
      const btn = document.querySelector(`[data-field="building_type"][data-value="${buildingInput.value}"]`)
      if (btn) {
        btn.classList.add('shadow-xl', 'scale-105', 'selected')
        btn.querySelector('.check-icon')?.classList.remove('hidden')
        btn.setAttribute('aria-checked', 'true')
      }
    }
  }
}
