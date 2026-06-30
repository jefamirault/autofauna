# Prints the Active Storage Disk-service relative paths (key[0..1]/key[2..3]/key)
# for every image attached to a given user's plants. Feed the output to
# `rsync --files-from` to sync only that user's uploads.
#
# Usage: bin/rails runner util/list_user_storage_paths.rb <email>
#
# Only originals are listed (record_type "Plant"); variants are excluded since
# they regenerate on demand locally.
email = ARGV[0]
abort("usage: bin/rails runner util/list_user_storage_paths.rb <email>") if email.blank?

user = User.find_by(email: email)
abort("no user with email #{email.inspect}") if user.nil?

ActiveStorage::Blob
  .joins(:attachments)
  .where(active_storage_attachments: { record_type: "Plant", record_id: user.plants.select(:id) })
  .distinct
  .pluck(:key)
  .each { |key| puts [key[0..1], key[2..3], key].join("/") }
