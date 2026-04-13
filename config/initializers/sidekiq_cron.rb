Sidekiq.configure_server do |config|
  config.on(:startup) do
    Sidekiq::Cron::Job.load_from_hash(
      "billing_renewal" => {
        "cron"  => "0 9 * * *",   # 매일 오전 9시 (KST)
        "class" => "BillingRenewalJob",
        "queue" => "default"
      }
    )
  end
end
