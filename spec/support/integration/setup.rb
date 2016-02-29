module IntegrationSetup
  def start_server(config={})
    @config_filepath = create_config_file(config)
    @pid = run_cmd("RACK_ENV=production BITS_CONFIG_FILE=#{@config_filepath} rackup")

    (1..10).each do |attempt|
      begin
        make_get_request('/')
      rescue
        raise "Giving up starting http server after #{attempt} attempts" if attempt == 10
        sleep 0.5
      end
    end
  end

  def stop_server
    return if @pid.nil?
    graceful_kill(@pid)
    FileUtils.rm_f(@config_filepath)
  end
end

module IntegrationSetupHelpers
  def run_cmd(cmd, opts={})
    opts[:env] ||= {}
    project_path = File.join(File.dirname(__FILE__), '../../..')
    spawn_opts = {
      chdir: project_path,
      out: '/dev/null',
      err: '/dev/null',
      pgroup: true,
    }

    pid = Process.spawn(opts[:env], cmd, spawn_opts)

    if opts[:wait]
      Process.wait(pid)
      fail "`#{cmd}` exited with #{$CHILD_STATUS}" unless $CHILD_STATUS.success?
    end

    pid
  end

  def graceful_kill(pid)
    pgid = Process.getpgid(pid)
    Process.kill('TERM', -pgid)
    Timeout.timeout(1) do
      Process.wait(pid)
    end
  rescue Timeout::Error
    Process.detach(pid)
    Process.kill('KILL', -pgid)
  rescue Errno::ESRCH
    true
  end

  def process_alive?(pid)
    Process.kill(0, pid)
    true
  rescue Errno::ESRCH
    false
  end
end
