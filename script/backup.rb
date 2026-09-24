#!/usr/bin/env ruby
require 'fileutils'

puts "Starting safe transactional checkpoint flush..."
system("sqlite3 /app/storage/production.sqlite3 'PRAGMA wal_checkpoint(TRUNCATE);'")

BACKUP_DIR = "/app/storage/backups"
FileUtils.mkdir_p(BACKUP_DIR)
TIMESTAMP = Time.now.strftime("%Y%m%d_%H%M%S")
FILENAME = "backup_#{TIMESTAMP}.tar.gz"

targets = ["production.sqlite3"]
targets << "media" if Dir.exist?("/app/storage/media")

puts "Compressing structural components: #{targets.join(', ')}..."
Dir.chdir("/app/storage") do
  if system("tar -czf #{BACKUP_DIR}/#{FILENAME} #{targets.join(' ')}")
    puts "Automated recovery backup package compiled successfully: #{FILENAME}"
  else
    puts "Error: Failed to package filesystem state."
    exit 1
  end
end
