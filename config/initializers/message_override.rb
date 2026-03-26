# easycodefrb gem이 Message를 Module로 정의하여
# app/models/message.rb (ActiveRecord) 와 이름 충돌 발생.
# Rails 앱 부팅 시 우리 모델로 강제 덮어쓴다.
Rails.application.config.after_initialize do
  Object.send(:remove_const, :Message) if defined?(Message) && !Message.is_a?(Class)
  require_dependency Rails.root.join("app/models/message").to_s
end
