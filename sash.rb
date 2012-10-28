require 'fileutils'
require 'yaml'

# This is a savable hash, it can be configured and used to store whatever the
# contents of the hash are for loading later.  Will serialize in yaml to keep it part
# of the stdlib
class Sash < Hash

  attr_accessor :file
  attr_accessor :backup
  attr_accessor :mode
  attr_accessor :load

  def initialize(params = {})
    @file = params[:file] if params[:file]
    @backup = params[:backup] if params[:backup]
    @mode = params[:mode] if params[:mode]
    @load = load if params[:load]
    load if @load
  end

  # The base directory of the save file.
  def basedir
    return nil if !file
    File.dirname File.absolute_path @file
  end

  # The save file plus an extension.
  def backup_file
    "#{@file}.bak"
  end

  # Save the hash to the file, check for backup and set_mode.
  def save
    if any?
      FileUtils.mkdir_p basedir if !Dir.exist? basedir
      backup if @backup

      # I do this the long way because I want an immediate sync.
      f = open(@file, 'w')
      f.write YAML::dump self
      f.sync
      f.close

      set_mode if @mode
    end
    true
  end

  # Save the hash to a file, overwriting if necessary.
  def save!
    delete_file
    save
  end

  # Load the save file into self.
  def load
    if @file && File.exist?(@file) && File.stat(@file).size > 0
      h = YAML::load open(@file, 'r').read
      h.each { |k,v| self[k.to_sym] = v}
      return true
    end
    false
  end

  # Backup the file, this is a two step process.
  def backup
    return false if !@file || !backup_file
    FileUtils.cp @file, backup_file if File.file? @file
    true
  end

  # Set the mode of both the save file and backup file.
  def set_mode
    # Why are we trying to set_mode when we don't even have a file?
    return false if !@file
    File.chmod @mode, @file if File.exist? @file

    # the backup file may not exist for whatever reason, lets not shit if it doesn't.
    return true if !backup_file
    File.chmod @mode, backup_file if File.exist? backup_file
    true
  end

  private

  # Delete the save file.
  def delete_file
    return false if !@file
    FileUtils.rm @file if File.file? @file
    returne true
  end
end
