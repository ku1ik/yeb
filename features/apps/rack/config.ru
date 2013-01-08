boot_timestamp = Time.now.to_f

app = lambda do |env|
  # body = `date`
  body = "hello from rack app\ntimestamp: #{boot_timestamp}"
  [200, { 'Content-type' => 'text/plain' }, [body]]
end

run app
