require 'asir'
require 'time'


module ASIR
class Main
  attr_accessor :verb, :adjective, :object, :identifier
  attr_accessor :config_rb, :config
  attr_accessor :log_dir, :pid_dir
  attr_accessor :verbose
  attr_accessor :exit_code

  def initialize
    @verbose = 0
    @progname = File.basename($0)
    @log_dir = find_writable_directory :log_dir,
      ENV['ASIR_LOG_DIR'],
      '/var/log/asir',
      '~/asir/log',
      '/tmp'
    @pid_dir = find_writable_directory :pid_dir,
      ENV['ASIR_PID_DIR'],
      '/var/run/asir',
      '~/asir/run',
      '/tmp'
    @exit_code = 0
  end

  def find_writable_directory kind, *list
    list.
      reject { | p | ! p }.
      map { | p |  File.expand_path(p) }.
      find { | p | File.writable?(p) } or
      raise "Cannot find writable directory for #{kind}"
  end

  def parse_args! args = ARGV.dup
    @args = args
    until args.empty?
      case args.first
      when /^([a-z0-9_]+=)(.*)/i
        k, v = $1.to_sym, $2
        args.shift
        v = v.to_i if v == v.to_i.to_s
        send(k, v)
      else
        break
      end
    end
    @verb, @adjective, @object, @identifier = args.map{|x| x.to_sym}
    @identifier ||= :'0'
    self
  end

  def log_str
    "#{Time.now.gmtime.iso8601(4)} #{$$} #{log_str_no_time}"
  end

  def log_str_no_time
    "#{@progname} #{@verb} #{@adjective} #{@object} #{@identifier}"
  end

  def run!
    unless verb && adjective && object
      @exit_code = 1
      return usage!
    end
    config!(:config)
    # $stderr.puts "log_file = #{log_file.inspect}"
    case self.verb
    when :restart
      self.verb = :stop
      _run_verb! && sleep(1)
      self.verb = :start
      _run_verb!
    else
      _run_verb!
    end
    self
  rescue ::Exception => exc
    $stderr.puts "#{log_str} ERROR\n#{exc.inspect}\n  #{exc.backtrace * "\n  "}"
    @exit_code += 1
    self
  end

  def _run_verb!
    sel = :"#{verb}_#{adjective}_#{object}!"
    if @verbose >= 3
      $stderr.puts "verb      = #{verb.inspect}"
      $stderr.puts "adjective = #{adjective.inspect}"
      $stderr.puts "object    = #{object.inspect}"
      $stderr.puts "sel       = #{sel.inspect}"
    end
    send(sel)
  rescue ::Exception => exc
    $stderr.puts "#{log_str} ERROR\n#{exc.inspect}\n  #{exc.backtrace * "\n  "}"
    @exit_code += 1
    raise
    nil
  end

  def method_missing sel, *args
    log "method_missing #{sel}" if @verbose >= 3
    case sel.to_s
    when /^start_([^_]+)_worker!$/
      _start_worker!
    when /^status_([^_]+)_([^_]+)!$/
      pid = server_pid
      puts "#{log_str} pid #{pid}"
      system("ps -fw -p #{pid}")
    when /^log_([^_]+)_([^_]+)!$/
      puts log_file
    when /^taillog_([^_]+)_([^_]+)!$/
      exec "tail -f #{log_file.inspect}"
    when /^pid_([^_]+)_([^_]+)!$/
      puts "#{pid_file} #{File.read(pid_file) rescue nil}"
    when /^stop_([^_]+)_([^_]+)!$/
      kill_server!
    else
      super
    end
  end

  def usage!
    $stderr.puts <<"END"
SYNOPSIS:
  asir [ <<options>> ... ] <<verb>> <<adjective>> <<object>> [ <<identifier>> ]

OPTIONS:
  config_rb=file.rb ($ASIR_LOG_DIR)
  pid_dir=dir/      ($ASIR_PID_DIR)
  log_dir=dir/      ($ASIR_LOG_DIR)
  verbose=[0-9]

VERBS:
  start
  stop
  restart
  status
  log
  pid

ADJECTIVE-OBJECTs:
  beanstalk conduit
  beanstalk worker
  zmq worker
  webrick worker

EXAMPLES:

  export ASIR_CONFIG_RB="some_system/asir_config.rb"
  asir start beanstalk conduit
  asir status beanstalk conduit

  asir start webrick worker

  asir start beanstalk worker 1
  asir start beanstalk worker 2

  asir start zmq worker
  asir start zmq worker 1
  asir start zmq worker 2
END
  end

  def start_beanstalk_conduit!
    fork_server! "beanstalkd"
  end

  def _start_worker! type = adjective
    log "start_worker! #{type}"
    type = type.to_s
    fork_server! do
      transport_file = "asir/transport/#{type}"
      log "loading #{transport_file}"
      require transport_file
      _create_transport ASIR::Transport.const_get(type[0..0].upcase + type[1..-1])
      _run_workers!
    end
  end

  ################################################################

  def config_rb
    @config_rb ||=
      File.expand_path(ENV['ASIR_CONFIG_RB'] || 'config/asir_config.rb')
  end

  def config_lambda
    @config_lambda ||=
      begin
        file = config_rb
        $stderr.puts "#{log_str} loading #{file} ..." if @verbose >= 1
        expr = File.read(file)
        expr = "begin; lambda do | asir |; #{expr}\n end; end"
        cfg = Object.new.send(:eval, expr, binding, file, 1)
        # cfg = load file
        # $stderr.puts "#{log_str} loading #{file} DONE" if @verbose >= 1
        raise "#{file} did not return a Proc, returned a #{cfg.class}" unless Proc === cfg
        cfg
      end
  end

  def config! verb = @verb
    (@config ||= { })[verb] ||=
      begin
        save_verb = @verb
        @verb = verb
        $stderr.puts "#{log_str} calling #{config_rb} asir.verb=#{@verb.inspect} ..." if @verbose >= 1
        cfg = config_lambda.call(self)
        $stderr.puts "#{log_str} calling #{config_rb} asir.verb=#{@verb.inspect} DONE" if @verbose >= 1
        cfg
      ensure
        @verb = save_verb
      end
  end

  def pid_file
    "#{pid_dir}/#{asir_basename}.pid"
  end

  def log_file
    "#{log_dir}/#{asir_basename}.log"
  end

  def asir_basename
    "asir-#{adjective}-#{object}-#{identifier}"
  end

  def fork_server! cmd = nil, &blk
    pid = Process.fork do
      run_server! cmd, &blk
    end
    log "forked pid #{pid}"
    Process.detach(pid) # Forks a Thread?  We are gonna exit anyway.
    File.open(pid_file, "w+") { | o | o.puts pid }
    File.chmod(0666, pid_file) rescue nil

    # Wait and check if process still exists.
    sleep 3
    unless process_running? pid
      raise "Server process #{pid} died to soon?"
    end

    self
  end

  def run_server! cmd = nil
    lf = File.open(log_file, "a+")
    File.chmod(0666, log_file) rescue nil
    $stdin.close rescue nil
    STDIN.close rescue nil
    STDOUT.reopen(lf)
    $stdout.reopen(lf) if $stdout.object_id != STDOUT.object_id
    STDERR.reopen(lf)
    $stderr.reopen(lf) if $stderr.object_id != STDERR.object_id
    # Process.daemon rescue nil # Ruby 1.9.x only.
    lf.puts "#{log_str} starting pid #{$$}"
    begin
      if cmd
        exec(cmd)
      else
        yield
      end
    ensure
      lf.puts "#{log_str} finished pid #{$$}"
      File.unlink(pid_file) rescue nil
    end
    self
  rescue ::Exception => exc
    msg = "ERROR pid #{$$}\n#{exc.inspect}\n  #{exc.backtrace * "\n  "}"
    log msg, :stderr
    raise
    self
  end

  def kill_server!
    log "#{log_str} kill"
    pid = server_pid
    stop_pid! pid
  rescue ::Exception => exc
    log "#{log_str} ERROR\n#{exc.inspect}\n  #{exc.backtrace * "\n  "}", :stderr
    raise
  end

  def log msg, to_stderr = false
    if to_stderr
      $stderr.puts "#{log_str_no_time} #{msg}"
    end
    File.open(log_file, "a+") do | log |
      log.puts "#{log_str} #{msg}"
    end
  end

  def server_pid
    pid = File.read(pid_file).chomp!
    pid.to_i
  end

  def _create_transport default_class
    config!(:environment)
    case transport = config!(:transport)
    when default_class
      @transport = transport
    else
      raise "Expected config to return a #{default_class}, not a #{transport.class}"
    end
  end

  def worker_pids
    (@worker_pids ||= { })[@adjective] ||= { }
  end

  def _run_workers!
    $0 = "#{@progname} #{@adjective} #{@object} #{@identifier}"

    worker_id = 0
    @transport.prepare_server!
    worker_processes = @transport[:worker_processes] || 1
    (worker_processes - 1).times do
      wid = worker_id += 1
      pid = Process.fork do
        _run_transport_server! wid
      end
      Process.setgprp(pid, 0) rescue nil
      worker_pids[wid] = pid
      log "forked #{wid} pid #{pid}"
    end

    _run_transport_server!
  ensure
    log "worker 0 stopped"
    _stop_workers!
  end

  def _run_transport_server! wid = 0
    log "running transport worker #{@transport.class} #{wid}"
    config!(:start)
    $0 += " #{wid} #{@transport.uri rescue nil}"
    old_arg0 = $0.dup
    after_receive_message = @transport.after_receive_message || lambda { | transport, message | nil }
    @transport.after_receive_message = lambda do | transport, message |
      $0 = "#{old_arg0} #{transport.message_count} #{message.identifier}"
      after_receive_message.call(transport, message)
    end
    @transport.run_server!
    self
  end

  def _stop_workers!
    workers = worker_pids.dup
    worker_pids.clear
    workers.each do | wid, pid |
      config!(:stop)
      stop_pid! pid, "wid #{wid} "
    end
    workers.each do | wid, pid |
      wr = Process.waitpid(pid) rescue nil
      log "stopped #{wid} pid #{pid} => #{wr.inspect}", :stderr
    end
  ensure
    worker_pids.clear
  end

  def stop_pid! pid, msg = nil
    log "stopping #{msg}pid #{pid}", :stderr
    if process_running? pid
      log "TERM pid #{pid}"
      Process.kill('TERM', pid) rescue nil
      sleep 3
      if @force or process_running? pid
        log "KILL pid #{pid}", :stderr
        Process.kill('KILL', pid) rescue nil
      end
      if process_running? pid
        log "cant-stop pid #{pid}", :stderr
      end
    else
      log "not-running? pid #{pid}", :stderr
    end
  end

  def process_running? pid
    Process.kill(0, pid)
    true
  rescue ::Errno::ESRCH
    false
  rescue ::Exception => exc
    $stderr.puts "  DEBUG: process_running? #{pid} => #{exc.inspect}"
    false
  end

end # class
end # module

