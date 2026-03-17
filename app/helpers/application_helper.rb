module ApplicationHelper
  # ===== 라벨 헬퍼 (중복 제거) =====

  SYMPTOM_LABELS = {
    "wall_leak" => "벽면 누수", "ceiling_leak" => "천장 누수",
    "floor_leak" => "바닥 누수", "pipe_leak" => "배관 누수",
    "toilet_leak" => "화장실 누수", "outdoor_leak" => "외부 누수"
  }.freeze

  BUILDING_LABELS = {
    "apartment" => "아파트", "villa" => "빌라", "house" => "주택",
    "office" => "사무실", "store" => "상가", "factory" => "공장", "other_building" => "기타"
  }.freeze

  def symptom_label(type)
    SYMPTOM_LABELS[type.to_s] || type
  end

  def building_label(type)
    BUILDING_LABELS[type.to_s] || type
  end

  # ===== 상태 관련 =====

  def status_color(status)
    case status.to_s
    when "reported" then "teal"
    when "assigned" then "yellow"
    when "visiting" then "indigo"
    when "detecting" then "orange"
    when "no_leak_found" then "gray"
    when "estimate_pending", "estimate_submitted" then "purple"
    when "construction_agreed", "escrow_deposited" then "cyan"
    when "constructing" then "violet"
    when "construction_completed" then "teal"
    when "closed" then "green"
    when "cancelled" then "red"
    else "gray"
    end
  end

  def status_badge_classes(status)
    color = status_color(status)
    "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-#{color}-100 text-#{color}-800"
  end

  # ===== 버튼 클래스 통일 =====

  def btn_classes(variant = :primary, size = :md)
    base = "inline-flex items-center justify-center font-semibold rounded-xl transition-all duration-200 cursor-pointer"

    sizes = {
      sm: "px-3 py-1.5 text-xs",
      md: "px-4 py-2 text-sm",
      lg: "px-6 py-3 text-base"
    }

    variants = {
      primary:   "bg-primary-600 text-white hover:bg-primary-700 shadow-sm hover:shadow",
      secondary: "bg-gray-200 text-gray-700 hover:bg-gray-300",
      danger:    "bg-red-600 text-white hover:bg-red-700 shadow-sm hover:shadow",
      outline:   "border border-gray-300 text-gray-700 bg-white hover:bg-gray-50",
      success:   "bg-green-600 text-white hover:bg-green-700 shadow-sm hover:shadow",
      warning:   "bg-yellow-500 text-white hover:bg-yellow-600 shadow-sm hover:shadow",
      ghost:     "text-gray-600 hover:text-gray-900 hover:bg-gray-100"
    }

    [base, sizes[size], variants[variant]].compact.join(" ")
  end

  # ===== 입력 필드 클래스 통일 =====

  def input_classes(type = :text)
    base = "w-full border border-gray-200 rounded-xl focus:ring-2 focus:ring-primary-500 focus:border-primary-500 transition-colors text-gray-900 placeholder-gray-400 text-base"

    case type
    when :select
      "#{base} px-3 py-2.5"
    when :textarea
      "#{base} px-4 py-3"
    else
      "#{base} px-4 py-2.5"
    end
  end

  # ===== 포맷 헬퍼 =====

  def format_currency(amount)
    number_to_currency(amount.to_i, unit: "₩", precision: 0)
  end

  def format_date(date)
    date&.strftime("%Y-%m-%d") || "-"
  end

  def format_datetime(datetime)
    datetime&.strftime("%Y-%m-%d %H:%M") || "-"
  end

  # 알림의 notifiable 객체 → 적절한 경로 반환
  def notifiable_path(notifiable)
    case notifiable
    when Request
      if current_user&.master?
        masters_request_path(notifiable)
      else
        customers_request_path(notifiable)
      end
    when Master
      masters_profile_path
    when Customer
      customers_profile_path
    else
      root_path
    end
  rescue
    root_path
  end

  # 유저 타입에 따른 관리자 경로
  def admin_user_path(user)
    user.is_a?(Master) ? admin_master_path(user) : "#"
  end
end
