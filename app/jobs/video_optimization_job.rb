class VideoOptimizationJob < ApplicationJob
  queue_as :default

  def perform(leak_inspection_id)
    inspection = LeakInspection.find_by(id: leak_inspection_id)
    return unless inspection&.photo&.attached?
    return unless inspection.photo.content_type.start_with?("video/")
    return if inspection.photo.blob.metadata["compressed"]

    Rails.logger.info "[VideoOptimizationJob] Starting compression for LeakInspection ##{leak_inspection_id}"

    original_ext = inspection.photo.filename.extension.presence || "mp4"
    input_path = nil
    output_path = nil

    begin
      # 임시 파일로 다운로드
      input_path = Rails.root.join("tmp", "video_in_#{leak_inspection_id}.#{original_ext}").to_s
      output_path = Rails.root.join("tmp", "video_out_#{leak_inspection_id}.mp4").to_s

      File.open(input_path, "wb") { |f| f.write(inspection.photo.download) }

      movie = FFMPEG::Movie.new(input_path)
      original_size = File.size(input_path)

      Rails.logger.info "[VideoOptimizationJob] Original: #{(original_size / 1024.0 / 1024).round(1)}MB, duration: #{movie.duration.to_i}s"

      # 해상도 결정 (1080p 초과는 1080p로 다운스케일)
      vf_filter = if movie.height && movie.height > 1080
        "scale=-2:1080"
      elsif movie.width && movie.width > 1920
        "scale=1920:-2"
      else
        "scale=trunc(iw/2)*2:trunc(ih/2)*2"
      end

      # H.264 + AAC로 재인코딩 (CRF 28 = 높은 압축, 좋은 품질)
      options = {
        video_codec: "libx264",
        audio_codec: "aac",
        audio_bitrate: "64k",
        custom: %W[-crf 28 -preset fast -vf #{vf_filter} -movflags +faststart]
      }

      movie.transcode(output_path, options)

      if File.exist?(output_path)
        compressed_size = File.size(output_path)
        ratio = (compressed_size.to_f / original_size * 100).round(1)
        Rails.logger.info "[VideoOptimizationJob] Compressed: #{(compressed_size / 1024.0 / 1024).round(1)}MB (#{ratio}% of original)"

        # 압축된 파일이 원본보다 작을 때만 교체
        if compressed_size < original_size
          inspection.photo.attach(
            io: File.open(output_path, "rb"),
            filename: "video_optimized.mp4",
            content_type: "video/mp4"
          )
          # 압축 완료 마킹 (재처리 방지)
          inspection.photo.blob.update_column(:metadata,
            inspection.photo.blob.metadata.merge("compressed" => true, "original_size" => original_size))
          Rails.logger.info "[VideoOptimizationJob] ✅ Replaced with compressed version"
        else
          Rails.logger.info "[VideoOptimizationJob] Skipped: compressed file is larger"
        end
      end
    rescue FFMPEG::Error => e
      Rails.logger.error "[VideoOptimizationJob] FFmpeg error: #{e.message}"
    rescue => e
      Rails.logger.error "[VideoOptimizationJob] Error: #{e.message}"
    ensure
      File.delete(input_path) if input_path && File.exist?(input_path)
      File.delete(output_path) if output_path && File.exist?(output_path)
    end
  end
end
