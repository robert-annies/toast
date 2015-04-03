xml.apple(:uri => request.base_url + request.script_name + apple.uri_path) do
  xml.name apple.name
  xml.number apple.number
end
