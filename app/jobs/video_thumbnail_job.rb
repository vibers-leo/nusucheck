# frozen_string_literal: true

class VideoThumbnailJob < ApplicationJob
  queue_as :default

  def perform(request_id)
    request = Request.find(request_id)
    return if request.video_thumbnail.attached?
    return unless request.videos.attached?

    video = request.videos.first
    tmpfile = Tempfile.new(["thumb", ".jpg"])

    begin
      video.open do |file|
        system(
          "ffmpeg", "-i", file.path,
          "-ss", "00:00:01", "-frames:v", "1",
          "-vf", "scale=320:-1",
          "-y", tmpfile.path,
          [:out, :err] => "/dev/null"
        )
      end

      if File.size?(tmpfile.path)
        request.video_thumbnail.attach(
          io: File.open(tmpfile.path),
          filename: "thumb_#{request.id}.jpg",
          content_type: "image/jpeg"
        )
      end
    ensure
      tmpfile.close
      tmpfile.unlink
    end
  end
end
