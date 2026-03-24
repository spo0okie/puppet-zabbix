Facter.add(:runtime_dir) do
  confine :kernel => 'Linux'

  setcode do
    if File.directory?('/run')
      '/run'
    elsif File.directory?('/var/run')
      '/var/run'
    else
      nil
    end
  end
end
