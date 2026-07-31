# Prints the Active Storage Disk-service relative paths (key[0..1]/key[2..3]/key)
# for every image attached to records in a given user's projects. Feed the output to
# `rsync --files-from` to sync only that user's uploads.
#
# Usage: bin/rails runner util/list_user_storage_paths.rb <email>
#
# Both originals (record_type "Plant") and their tracked variants are listed.
# Variants must be included: `track_variants` is on (Rails >= 6.1 defaults), so the
# DB dump carries active_storage_variant_records rows over from production. Rails
# treats a tracked variant as already processed and will NOT regenerate it locally —
# it serves a URL to a file that was never synced, which renders as a blank image.
email = ARGV[0]
abort("usage: bin/rails runner util/list_user_storage_paths.rb <email>") if email.blank?

user = User.find_by(email: email)
abort("no user with email #{email.inspect}") if user.nil?

project_ids = user.projects.select(:id)

# Every attachable model in the app, scoped to this user's projects: Plant gets
# :custom_image from PlantGraphics, Location and Tank get :picture from HasPicture.
# Add new attachable models here or their uploads silently won't sync.
record_scopes = {
  "Plant" => Plant.where(project_id: project_ids),
  "Location" => Location.where(project_id: project_ids),
  "Tank" => Tank.where(project_id: project_ids)
}

original_ids = record_scopes.flat_map do |record_type, scope|
  ActiveStorage::Attachment.where(record_type: record_type, record_id: scope.select(:id)).pluck(:blob_id)
end.uniq

variant_ids = ActiveStorage::Attachment
  .where(
    record_type: "ActiveStorage::VariantRecord",
    record_id: ActiveStorage::VariantRecord.where(blob_id: original_ids).select(:id)
  )
  .pluck(:blob_id)

ActiveStorage::Blob.where(id: (original_ids + variant_ids).uniq).pluck(:key).each do |key|
  puts [key[0..1], key[2..3], key].join("/")
end
