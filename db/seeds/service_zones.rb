# 서울 구역
seoul_zones = [
  { name: "강남", districts: ["강남구"], population: 530000, max_slots: 3, sort_order: 1 },
  { name: "서초", districts: ["서초구"], population: 420000, max_slots: 3, sort_order: 2 },
  { name: "송파", districts: ["송파구"], population: 670000, max_slots: 3, sort_order: 3 },
  { name: "강동", districts: ["강동구"], population: 470000, max_slots: 3, sort_order: 4 },
  { name: "마포·서대문", districts: ["마포구", "서대문구"], population: 690000, max_slots: 3, sort_order: 5 },
  { name: "영등포·동작", districts: ["영등포구", "동작구"], population: 740000, max_slots: 3, sort_order: 6 },
  { name: "관악·금천", districts: ["관악구", "금천구"], population: 720000, max_slots: 3, sort_order: 7 },
  { name: "구로·양천", districts: ["구로구", "양천구"], population: 870000, max_slots: 3, sort_order: 8 },
  { name: "강서", districts: ["강서구"], population: 580000, max_slots: 3, sort_order: 9 },
  { name: "노원·도봉", districts: ["노원구", "도봉구"], population: 820000, max_slots: 3, sort_order: 10 },
  { name: "강북·성북", districts: ["강북구", "성북구"], population: 710000, max_slots: 3, sort_order: 11 },
  { name: "중랑·동대문", districts: ["중랑구", "동대문구"], population: 730000, max_slots: 3, sort_order: 12 },
  { name: "성동·광진", districts: ["성동구", "광진구"], population: 670000, max_slots: 3, sort_order: 13 },
  { name: "도심", districts: ["중구", "종로구", "용산구"], population: 500000, max_slots: 3, sort_order: 14 },
  { name: "은평", districts: ["은평구"], population: 480000, max_slots: 3, sort_order: 15 },
]

seoul_zones.each do |data|
  ServiceZone.find_or_create_by!(region: "서울", name: data[:name]) do |zone|
    zone.assign_attributes(data)
  end
end

# 부산 구역
busan_zones = [
  { name: "해운대", districts: ["해운대구"], population: 250000, max_slots: 3, sort_order: 1 },
  { name: "부산진·동래", districts: ["부산진구", "동래구"], population: 600000, max_slots: 3, sort_order: 2 },
  { name: "남구·수영", districts: ["남구", "수영구"], population: 400000, max_slots: 3, sort_order: 3 },
  { name: "사상·사하", districts: ["사상구", "사하구"], population: 500000, max_slots: 3, sort_order: 4 },
  { name: "북구·강서", districts: ["북구", "강서구"], population: 400000, max_slots: 3, sort_order: 5 },
  { name: "금정·연제", districts: ["금정구", "연제구"], population: 450000, max_slots: 3, sort_order: 6 },
  { name: "도심", districts: ["중구", "서구", "동구", "영도구"], population: 300000, max_slots: 3, sort_order: 7 },
  { name: "기장", districts: ["기장군"], population: 200000, max_slots: 3, sort_order: 8 },
]

busan_zones.each do |data|
  ServiceZone.find_or_create_by!(region: "부산", name: data[:name]) do |zone|
    zone.assign_attributes(data)
  end
end

puts "✅ 서비스 구역 생성 완료: 서울 #{seoul_zones.size}개, 부산 #{busan_zones.size}개"
puts "   총 슬롯: 서울 #{seoul_zones.sum { |z| z[:max_slots] }}개, 부산 #{busan_zones.sum { |z| z[:max_slots] }}개"
