console_encoding = Java::java.lang.System.get_property('console.encoding') || (java.io.File.separator == '\\' ? 'ibm866' : 'utf-8')
STDOUT.set_encoding("#{console_encoding}:utf-8", {:invalid => :replace, :undef => :replace, :replace => '?'})
STDERR.set_encoding("#{console_encoding}:utf-8", {:invalid => :replace, :undef => :replace, :replace => '?'})
STDIN.set_encoding("#{console_encoding}:utf-8", {:invalid => :replace, :undef => :replace, :replace => '?'})

require 'iconv'

class TfsCommands 
  CHANGESET = "tf changeset %s /noprompt"
  LABELS    = "tf labels %s /format:detailed /noprompt"
  LABEL     = "tf label %s %s /version:%{version}"
  def self.files_in_label labelname
    LABELS % labelname
  end 
  def self.files_of_changeset changesetnumber 
    CHANGESET % changesetnumber 
  end 
  def self.label_files labelname, itemspec, versionspec
    LABEL % [labelname, itemspec, versionspec]
  end 
end 

class TFS
  TFS_DIR = "C:\\Program Files (x86)\\Microsoft Visual Studio 11.0\\Common7\\IDE"
  
  def self.get_files(changeset_or_label)
    raise ArgumentError, "No changeset number nor label name provided!" unless changeset_or_label
    label = changeset_or_label
    changeset = Integer(changeset_or_label) rescue nil 
    response = execute(changeset ? TfsCommands.files_of_changeset(changeset) : TfsCommands.files_in_label(label))
    raise Exception, "No response" if response.empty?
    response + "\n"
  end
  
  def self.label_files labelname, files
    response = []
    files.group_by{|file| file[:version]}.each do |version, version_files|
      text = TfsCommands.label_files(labelname, version_files.map(&:inspect).join(" "), version)
      puts text 
      response << execute(text)
    end 
    response.join() + "\n"
  end 
  
  def self.execute text
    response = ""
    Dir.chdir(TFS_DIR) do 
      open("| #{text}") do |pipe|
        until pipe.eof?
          response << pipe.readline
        end
      end
    end
    from_win(response)
  end 
  
  def self.from_win text
    Iconv.iconv('utf-8', 'windows-1251', text)[0]
  rescue => err
    puts "error: " + err.message
    text
  end 
end