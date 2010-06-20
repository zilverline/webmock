module EMHttpRequestSpecHelper

  def failed
    EventMachine.stop
    fail
  end

  def http_request(method, uri, options = {}, &block)
    response = nil
    error = nil
    EventMachine.run {
      request = EventMachine::HttpRequest.new(uri)
      http = request.send(:setup_request, method, {
        :timeout => 2, 
        :body => options[:body], 
        :head => options[:headers]}, &block)
      http.errback {
        error = http.errors         
        failed 
      }
      headers = {}
      if http.response_header
        http.response_header.each do |k,v|
          v = v.join(", ") if v.is_a?(Array)
          headers[k] = v 
        end
      end
      http.callback {
        response = OpenStruct.new({
          :body => http.response,
          :headers => WebMock::Util::Headers.normalize_headers(headers),          
          :message => http.response_header.http_reason,
          :status => http.response_header.status.to_s
        })
        EventMachine.stop
      }
    }
    raise error if error
    response
  end

  def client_timeout_exception_class
    "WebMock timeout error"
  end

  def connection_refused_exception_class
    ""
  end

  def default_client_request_headers(request_method = nil, has_body = false)
    nil
  end

  def setup_expectations_for_real_request(options = {})
  end

  def http_library
    :em_http_request
  end

end
