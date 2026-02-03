namespace :guests do
  desc "Remove guest accounts older than 30 days"
  task cleanup: :environment do
    count = User.where(guest: true).where("created_at < ?", 30.days.ago).destroy_all.size
    puts "Removed #{count} stale guest accounts."
  end
end
