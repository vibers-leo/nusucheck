import { Controller } from "@hotwired/stimulus"

// Toss/미소 스타일 원퀘스천 위자드 컨트롤러
export default class extends Controller {
  static targets = [
    "step", "progressBar", "nextBtn", "skipNextGroup", "submitBtn",
    "buttonGroup", "hiddenField", "requiredInput", "form",
    "summarySymptom", "summaryBuilding", "summaryAddress"
  ]
  static values = {
    currentStep: { type: Number, default: 1 },
    totalSteps: { type: Number, default: 7 }
  }

  // 각 스텝의 유형: "button" = 버튼 선택, "form" = 일반 폼, "optional" = 건너뛰기 가능, "submit" = 마지막
  get stepTypes() {
    return ["button", "button", "form", "optional", "optional", "optional", "submit"]
  }

  // 선택 라벨 맵
  get symptomLabels() {
    return {
      wall_leak: "벽면 누수",
      ceiling_leak: "천장 누수",
      floor_leak: "바닥 누수",
      pipe_leak: "배관 누수",
      toilet_leak: "화장실 누수",
      outdoor_leak: "외부 누수"
    }
  }

  get buildingLabels() {
    return {
      apartment: "아파트",
      villa: "빌라/연립",
      house: "단독주택",
      office: "사무실",
      retail_store: "상가",
      factory: "공장",
      other_building: "기타"
    }
  }

  connect() {
    this.selections = {}
    this.showStep(this.currentStepValue)
    this.updateProgress()
    this.updateButtons()
  }

  // 버튼 선택 (증상, 건물유형)
  selectOption(event) {
    event.preventDefault()
    const button = event.currentTarget
    const group = button.closest("[data-check-wizard-target='buttonGroup']")
    const field = group.dataset.field
    const value = button.dataset.value

    // 이전 선택 해제 (체크마크 숨기기)
    group.querySelectorAll(".select-button").forEach(btn => {
      btn.classList.remove("border-primary-500", "bg-primary-50", "ring-2", "ring-primary-200")
      btn.classList.add("border-gray-200", "bg-white")
      btn.setAttribute("aria-checked", "false")
      const check = btn.querySelector(".select-check")
      if (check) {
        check.classList.add("hidden")
      }
    })

    // 현재 선택 활성화 (체크마크 표시)
    button.classList.remove("border-gray-200", "bg-white")
    button.classList.add("border-primary-500", "bg-primary-50", "ring-2", "ring-primary-200")
    button.setAttribute("aria-checked", "true")
    const check = button.querySelector(".select-check")
    if (check) {
      check.classList.remove("hidden")
    }

    // hidden field에 값 설정
    this.hiddenFieldTargets.forEach(input => {
      if (input.name.includes(field)) {
        input.value = value
      }
    })

    this.selections[field] = value
    this.enableNextButton()

    // 버튼 선택 스텝은 짧은 딜레이 후 자동 전진
    setTimeout(() => {
      this.next({ preventDefault: () => {} })
    }, 400)
  }

  // 키보드 네비게이션 처리
  handleKeydown(event) {
    const button = event.currentTarget

    // Enter 또는 Space로 선택
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault()
      this.selectOption(event)
    }

    // Escape로 폼 닫기
    if (event.key === "Escape") {
      event.preventDefault()
      this.close(event)
    }

    // 화살표 키로 버튼 간 이동
    if (event.key === "ArrowDown" || event.key === "ArrowRight" ||
        event.key === "ArrowUp" || event.key === "ArrowLeft") {
      event.preventDefault()
      const group = button.closest("[data-check-wizard-target='buttonGroup']")
      const buttons = Array.from(group.querySelectorAll(".select-button"))
      const currentIndex = buttons.indexOf(button)
      let nextIndex

      if (event.key === "ArrowDown" || event.key === "ArrowRight") {
        nextIndex = (currentIndex + 1) % buttons.length
      } else {
        nextIndex = (currentIndex - 1 + buttons.length) % buttons.length
      }

      buttons[nextIndex].focus()
    }
  }

  next(event) {
    if (event.preventDefault) event.preventDefault()

    if (!this.validateCurrentStep()) return

    if (this.currentStepValue < this.totalStepsValue) {
      this.currentStepValue++
      this.showStep(this.currentStepValue)
      this.updateProgress()
      this.updateButtons()
      this.scrollToTop()

      // 마지막 스텝이면 요약 업데이트
      if (this.currentStepValue === this.totalStepsValue) {
        this.updateSummary()
      }
    }
  }

  skip(event) {
    event.preventDefault()
    // 선택사항 스텝은 유효성 검사 없이 다음으로
    if (this.currentStepValue < this.totalStepsValue) {
      this.currentStepValue++
      this.showStep(this.currentStepValue)
      this.updateProgress()
      this.updateButtons()
      this.scrollToTop()

      if (this.currentStepValue === this.totalStepsValue) {
        this.updateSummary()
      }
    }
  }

  prevOrClose(event) {
    event.preventDefault()
    if (this.currentStepValue > 1) {
      this.currentStepValue--
      this.showStep(this.currentStepValue)
      this.updateProgress()
      this.updateButtons()
      this.scrollToTop()
    } else {
      this.close(event)
    }
  }

  close(event) {
    event.preventDefault()
    if (confirm("작성 중인 내용이 사라져요. 나가시겠어요?")) {
      window.history.back()
    }
  }

  goToStep(event) {
    event.preventDefault()
    const step = parseInt(event.currentTarget.dataset.step)
    if (step >= 1 && step <= this.totalStepsValue) {
      this.currentStepValue = step
      this.showStep(this.currentStepValue)
      this.updateProgress()
      this.updateButtons()
      this.scrollToTop()
    }
  }

  showStep(stepNumber) {
    this.stepTargets.forEach((step, index) => {
      if (index + 1 === stepNumber) {
        step.classList.remove("hidden")
        // 페이드인 애니메이션
        step.style.opacity = "0"
        step.style.transform = "translateY(12px)"
        requestAnimationFrame(() => {
          step.style.transition = "opacity 0.3s ease, transform 0.3s ease"
          step.style.opacity = "1"
          step.style.transform = "translateY(0)"

          // 애니메이션 후 포커스 이동
          setTimeout(() => {
            this.focusFirstElement(step)
          }, 300)
        })
      } else {
        step.classList.add("hidden")
      }
    })
  }

  // 단계의 첫 번째 포커스 가능한 요소에 포커스
  focusFirstElement(step) {
    // 버튼 그룹의 첫 번째 버튼
    const firstButton = step.querySelector(".select-button")
    if (firstButton) {
      firstButton.focus()
      return
    }

    // 또는 첫 번째 입력 필드
    const firstInput = step.querySelector("input:not([type='hidden']), textarea")
    if (firstInput && !firstInput.readOnly) {
      firstInput.focus()
    }
  }

  updateProgress() {
    const percentage = (this.currentStepValue / this.totalStepsValue) * 100
    if (this.hasProgressBarTarget) {
      this.progressBarTarget.style.width = `${percentage}%`
    }
  }

  updateButtons() {
    const stepType = this.stepTypes[this.currentStepValue - 1]
    const isLast = this.currentStepValue === this.totalStepsValue

    // 모든 버튼 그룹 숨기기
    if (this.hasNextBtnTarget) this.nextBtnTarget.classList.add("hidden")
    if (this.hasSkipNextGroupTarget) this.skipNextGroupTarget.classList.add("hidden")
    if (this.hasSubmitBtnTarget) this.submitBtnTarget.classList.add("hidden")

    if (isLast) {
      // 제출 버튼
      if (this.hasSubmitBtnTarget) this.submitBtnTarget.classList.remove("hidden")
    } else if (stepType === "optional") {
      // 건너뛰기 + 다음
      if (this.hasSkipNextGroupTarget) this.skipNextGroupTarget.classList.remove("hidden")
    } else if (stepType === "button") {
      // 버튼 선택 스텝: "다음" 비활성 상태로 표시 (선택하면 자동 전진)
      if (this.hasNextBtnTarget) {
        this.nextBtnTarget.classList.remove("hidden")
        this.disableNextButton()
      }
    } else {
      // 일반 폼 스텝
      if (this.hasNextBtnTarget) {
        this.nextBtnTarget.classList.remove("hidden")
        // 주소 필드가 있으면 채워져 있는지 확인
        this.checkFormValidity()
      }
    }
  }

  enableNextButton() {
    if (this.hasNextBtnTarget) {
      this.nextBtnTarget.disabled = false
      this.nextBtnTarget.classList.remove("bg-gray-200", "text-gray-400", "cursor-not-allowed")
      this.nextBtnTarget.classList.add("bg-primary-600", "text-white", "hover:bg-primary-700")
    }
  }

  disableNextButton() {
    if (this.hasNextBtnTarget) {
      this.nextBtnTarget.disabled = true
      this.nextBtnTarget.classList.add("bg-gray-200", "text-gray-400", "cursor-not-allowed")
      this.nextBtnTarget.classList.remove("bg-primary-600", "text-white", "hover:bg-primary-700")
    }
  }

  checkFormValidity() {
    const currentStepEl = this.stepTargets[this.currentStepValue - 1]
    const requiredInputs = currentStepEl.querySelectorAll("[required]")
    let allFilled = true

    requiredInputs.forEach(input => {
      if (!input.value || input.value.trim() === "") {
        allFilled = false
      }
    })

    if (allFilled && requiredInputs.length > 0) {
      this.enableNextButton()
    } else if (requiredInputs.length > 0) {
      this.disableNextButton()
    } else {
      // required가 없는 스텝은 항상 활성화
      this.enableNextButton()
    }
  }

  validateStep(event) {
    // 입력 시 실시간 유효성 체크
    this.checkFormValidity()
  }

  validateCurrentStep() {
    const stepType = this.stepTypes[this.currentStepValue - 1]

    if (stepType === "button") {
      const group = this.stepTargets[this.currentStepValue - 1].querySelector("[data-check-wizard-target='buttonGroup']")
      if (group) {
        const field = group.dataset.field
        if (!this.selections[field]) {
          this.shakeStep()
          return false
        }
      }
      return true
    }

    if (stepType === "optional") return true

    // form 타입 유효성 검사
    const currentStepEl = this.stepTargets[this.currentStepValue - 1]
    const requiredInputs = currentStepEl.querySelectorAll("[required]")
    let isValid = true

    requiredInputs.forEach(input => {
      if (!input.value || input.value.trim() === "") {
        isValid = false
        input.classList.add("border-red-400")
        // 에러 표시
        let err = input.parentElement.querySelector(".field-error")
        if (!err) {
          err = document.createElement("p")
          err.className = "field-error text-xs text-red-500 mt-1"
          err.textContent = "필수 항목이에요"
          input.parentElement.appendChild(err)
        }
      } else {
        input.classList.remove("border-red-400")
        const err = input.parentElement.querySelector(".field-error")
        if (err) err.remove()
      }
    })

    if (!isValid) this.shakeStep()
    return isValid
  }

  shakeStep() {
    const step = this.stepTargets[this.currentStepValue - 1]
    step.style.animation = "shake 0.4s ease"
    setTimeout(() => { step.style.animation = "" }, 400)
  }

  onFileChange() {
    // 파일 선택 시 다음 버튼 활성화 처리
    this.enableNextButton()
  }

  updateSummary() {
    const symptom = this.selections["symptom_type"]
    const building = this.selections["building_type"]

    if (this.hasSummarySymptomTarget && symptom) {
      this.summarySymptomTarget.textContent = this.symptomLabels[symptom] || symptom
    }
    if (this.hasSummaryBuildingTarget && building) {
      this.summaryBuildingTarget.textContent = this.buildingLabels[building] || building
    }
    if (this.hasSummaryAddressTarget) {
      const addressField = this.element.querySelector("[name*='address']")
      if (addressField && addressField.value) {
        const detailField = this.element.querySelector("[name*='detailed_address']")
        let addr = addressField.value
        if (detailField && detailField.value) addr += " " + detailField.value
        this.summaryAddressTarget.textContent = addr
      }
    }
  }

  scrollToTop() {
    window.scrollTo({ top: 0, behavior: "smooth" })
  }
}
