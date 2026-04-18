Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(
      "https://nusucheck.com",
      "https://www.nusucheck.com",
      "https://nusucheck.vibers.co.kr",
      /\Ahttps:\/\/.*\.nusucheck\.com\z/,
      # 개발/Expo 로컬
      "http://localhost:3000",
      "http://localhost:19006",
      "http://127.0.0.1:3000"
    )

    resource "/api/*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options],
      expose: ["Authorization"],
      credentials: false
  end
end
