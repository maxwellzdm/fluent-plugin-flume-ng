# Fluent
#
# Copyright (C) 2015 Deming Zhu
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#
module Fluent

class FlumeNGInput < Input
  Plugin.register_input('flume_ng', self)

  def initialize
    require 'thrift'
    $:.unshift File.join(File.dirname(__FILE__), 'thrift')
    require 'flume_types'
    require 'flume_constants'
    require 'thrift_source_protocol'
    super
  end

  config_param :port,            :integer, :default => 56789
  config_param :bind,            :string,  :default => '0.0.0.0'
  config_param :tag_header,	     :string,  :default => nil
  config_param :default_tag,	 :string,  :default => 'flume'
  config_param :add_prefix,      :string,  :default => nil
  config_param :format,          :string,  :default => 'none'


  # Define `log` method for v0.10.42 or earlier
  unless method_defined?(:log)
    define_method(:log) { $log }
  end

  def configure(conf)
    super
  end

  def start
    log.debug "listening flume on #{@bind}:#{@port}"

    handler = FluentFlumeNGHandler.new
    handler.tag_header = @tag_header
    handler.default_tag = @default_tag
    handler.add_prefix = @add_prefix
    handler.format = @format
    handler.log = log

    processor = ThriftSourceProtocol::Processor.new handler
    @transport = Thrift::ServerSocket.new @bind, @port
    transport_factory = Thrift::FramedTransportFactory.new
    protocol_factory = Thrift::CompactProtocolFactory.new 

    unless ['none', 'json'].include? @format
      raise 'Unknown format: format=#{@format}'
    end

    @server = Thrift::SimpleServer.new processor, @transport, transport_factory, protocol_factory
    @thread = Thread.new(&method(:run))
  end

  def shutdown
    @transport.close
    @thread.join 
  end

  def run
    log.debug "starting server: #{@server}"
    @server.serve
  rescue
    log.error "unexpected error", :error=>$!.to_s
    log.error_backtrace
  end

  class FluentFlumeNGHandler
    attr_accessor :tag_header
    attr_accessor :default_tag
    attr_accessor :add_prefix
    attr_accessor :format
    attr_accessor :log

    def append(event)
      begin
        record = parse_record(event)
        tag = event.headers[@tag_header] || @default_tag
        if event.headers.has_key?("timestamp")
          timestamp = event.headers["timestamp"].to_i/1000.0
        else
          timestamp = Engine.now
        end
        if @add_prefix
          Engine.emit(@add_prefix + '.' + tag, timestamp, record)
        else
          Engine.emit(tag, timestamp, record)
        end
        return ::Status::OK
      rescue
        log.error "unexpected error", :error=>$!.to_s
        log.error_backtrace
        return ::Status::ERROR
      end
    end

    def appendBatch(events)
      es = MultiEventStream.new
      log.debug events.first.headers
      tag = events.first.headers[@tag_header] || @default_tag
      events.each { |event| 
        begin
          record = parse_record(event)
          if event.headers.has_key?("timestamp")
            timestamp = event.headers["timestamp"].to_i/1000.0
          else
            timestamp = Engine.now
          end
          es.add(timestamp, record)
        rescue
          log.error "unexpected error", :error=>$!.to_s
          log.error_backtrace
          return ::Status::ERROR
        end
      }

      unless es.empty?
        begin
          if @add_prefix
            Engine.emit_stream(@add_prefix + '.' + tag, es)
          else
            Engine.emit_stream(tag, es)
          end
          return ::Status::OK
        rescue
          log.error "unexpected error", :error=>$!.to_s
          log.error_backtrace
          return ::Status::ERROR
        end
      end
      return ::Status::OK
    end

    private
    def parse_record(event)
      case @format
      when 'none'
        return {'message'=>event.body.force_encoding('UTF-8')}
      when 'json'
        js = JSON.parse(event.body.force_encoding('UTF-8'))
        raise 'event body must be a Hash' unless js.is_a?(Hash)
        return js
      else
        raise 'Invalid format: #{@format}'
      end
    end
  end
end
end
