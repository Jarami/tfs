require "iconv"

def from_win text
  Iconv.iconv('utf-8', 'windows-1251', text)[0]
rescue => err
  text
end

class Command
  COMMANDS = {
    "set_info" => {regexp: /\w+ (\d+)\s*([save]*)/, tfs_command: ""},
    "load_set" => {regexp: /\w+ (\d+)\s*([last]*)/, tfs_command: ""},
    "load_file"=> {regexp: /\w+ (\w+)\s*(\d*)/, tfs_command: ""},
    "label"    => {regexp: /\w+ (\w+) set (\d+)/, tfs_command: ""},
    "help"=> {regexp: /help/, tfs_command: ""},
    "info"=> {regexp: /info/, tfs_command: ""},
    "exit"=> {regexp: /exit/, tfs_command: ""}
  }

  class UnknownUserCommand < Exception 
  end
  def initialize user_command
    @name, @args = Command.parse(user_command)
  end
  def self.parse user_command
    name = user_command.split[0]
    raise UnknownUserCommand, name if !COMMANDS.has_key?(name)
    regexp = COMMANDS[name][:regexp]
    user_command =~ regexp
    args = [$1,$2]
    return [name,args]
  rescue UnknownUserCommand => error
    puts "Неизвестная команда: #{error}. Введите help или info, чтобы получить информацию о возможных командах."
    return [nil,nil]
  end
  def execute
    puts @name.inspect, @args.inspect
  end
  def exit?
    @name=="exit"
  end
  def valid?
    !@name.nil?
  end  
end

class Console
  class WrongTFSPath < Exception 
  end
  
  def prepare
      prepare_console
      raise WrongTFSPath, "В системе отсутствует папка TFS " + Application::TFS.gsub(/"/, '') + ". Измените путь к папке с TFS (константа Application::TFS) в соответствии с вашей системой!"  if !tfs_exists?
      print_info
  rescue WrongTFSPath => error
    puts error      
  end
  
  def print_info
    puts %q{
Команды:

  set_info 11111 [save] - выдает названия файлов в наборе изменений 11111 [список файлов пишется в файл "11111_info.txt" в текущей папке]
  load_set 11111 [last] - сохраняет файлы из набора 11111 [последнюю версию этих файлов, если они изменялись позднее]
  load_file filename.rb [11111] - сохраняет последнюю версию файла "filename.rb" [версию 11111]
  label some_label set 11111 - сохраняет файлы из набора 11111 в метку some_label
  help | info - выдает этот текст
  exit - выйти
}
  end
  def user_command
    $stdin.readline().strip
  end
  private
  def tfs_exists?
    File.exist? Application::TFS.gsub(/"/, '')
  end
  def prepare_console
    console_encoding = Java::java.lang.System.get_property('console.encoding') || (java.io.File.separator == '\\' ? 'ibm866' : 'utf-8')
    STDOUT.set_encoding("#{console_encoding}:utf-8", {:invalid => :replace, :undef => :replace, :replace => '?'})
    STDERR.set_encoding("#{console_encoding}:utf-8", {:invalid => :replace, :undef => :replace, :replace => '?'})
    STDIN.set_encoding("#{console_encoding}:utf-8", {:invalid => :replace, :undef => :replace, :replace => '?'})
  end
end

class Application
# test
# jruby tfs.rb
  TFS = "C:\"\\Program Files (x86)\\Microsoft Visual Studio 11.0\\Common7\\IDE\""
  
  def initialize
    @console = Console.new
    @console.prepare
  end
  
  def run
    while !user_command.exit?
      execute if valid_command?
    end
  rescue Exception => error
    puts error, error.backtrace.join("\n")
  ensure
    $stdin.readline()
  end
  
  def self.run
    Application.new.run
  end
  
  private
  def user_command
    @user_command = Command.new(@console.user_command)
  end
  def execute
    @user_command.execute
  end
  def valid_command?
    @user_command.valid?
  end
end

Application.run 