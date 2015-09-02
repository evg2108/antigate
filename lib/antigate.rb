require "antigate/version"

module Antigate
  require 'net/http'
  require 'uri'
  require 'base64'

  def self.wrapper(key)
  	return Wrapper.new(key)
  end

  def self.balance(key)
  	wrapper = Wrapper.new(key)
  	return wrapper.balance
  end

  class Wrapper
  	attr_accessor :phrase, :regsense, :numeric, :calc, :min_len, :max_len, :domain

  	def initialize(key)
  		@key = key

  		@phrase = 0
  		@regsense = 0
  		@numeric = 0
  		@calc = 0
  		@min_len = 0
  		@max_len = 0
  		@domain = "antigate.com"
  	end


		# @param url_or_hash
		# if String, then used as URL of image
		# if Hash, then url_or_hash[:image] used as image content
		def recognize(url_or_hash, ext='')
  		added = nil
  		loop do
  			added = add(url_or_hash, ext)
        next if added.nil?
  			if added.include? 'ERROR_NO_SLOT_AVAILABLE'
  				sleep(1)
  				next
  			else
  				break
  			end
  		end
  		if added.include? 'OK'
  			id = added.split('|')[1]
  			sleep(10)
  			status = nil
  			loop do
  				status = status(id)
          next if status.nil?
  				if status.include? 'CAPCHA_NOT_READY'
  					sleep(1)
  					next
  				else
  					break
  				end
  			end
  			return [id, status.split('|')[1]]
  		else
  			return added
  		end
		end

  	def add(url_or_hash, ext)
  	  captcha = get_image_content(url_or_hash)
  		if captcha
  			params = {
  				'method' => 'base64',
  				'key' => @key,
  				'body' => Base64.encode64(captcha),
  				'ext' => ext,
  				'phrase' => @phrase,
  				'regsense' => @regsense,
  				'numeric' => @numeric,
  				'calc' => @calc,
  				'min_len' => @min_len,
  				'max_len' => @max_len
  			}
  			return Net::HTTP.post_form(URI("http://#{@domain}/in.php"), params).body rescue nil
  		end
  	end

		def get_image_content(url_or_hash)
			if url_or_hash.is_a? Hash
				url_or_hash[:image]
			else
				get_image_from_url(url_or_hash)
			end
		end

		def get_image_from_url(url)
			uri = URI.parse(url)
			http = Net::HTTP.new(uri.host, uri.port)
			http.use_ssl = (uri.port == 443)
			request = Net::HTTP::Get.new(uri.request_uri)
			response = http.request(request)
			response.body
		end

		def status(id)
  		return Net::HTTP.get(URI("http://#{@domain}/res.php?key=#{@key}&action=get&id=#{id}")) rescue nil
  	end

  	def bad(id)
  		return Net::HTTP.get(URI("http://#{@domain}/res.php?key=#{@key}&action=reportbad&id=#{id}")) rescue nil
  	end

  	def balance
  		return Net::HTTP.get(URI("http://#{@domain}/res.php?key=#{@key}&action=getbalance")) rescue nil
  	end
  end
end
