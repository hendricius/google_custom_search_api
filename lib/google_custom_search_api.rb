##
# Add search functionality (via Google Custom Search). Protocol reference at:
# http://www.google.com/coop/docs/cse/resultsxml.html
#
module GoogleCustomSearchApi
  extend self
  
  ##
  # Search the site.
  #
  def search(query, page = 0)
    # Get and parse results.
    url = url(query, page)
    puts url
    return nil unless results = fetch(url)
    results["items"] ||= []
    ResponseData.new(results)
  end
  
  # Convenience wrapper for the response Hash.
  # Converts keys to Strings. Crawls through all
  # member data and converts any other Hashes it
  # finds. Provides access to values through
  # method calls, which will convert underscored
  # to camel case.
  #
  # Usage:
  # 
  #  rd = ResponseData.new("AlphaBeta" => 1, "Results" => {"Gamma" => 2, "delta" => [3, 4]})
  #  puts rd.alpha_beta
  #  => 1
  #  puts rd.alpha_beta.results.gamma
  #  => 2
  #  puts rd.alpha_beta.results.delta
  #  => [3, 4]
  #
  class ResponseData < Hash
  private
    def initialize(data={})
      data.each_pair {|k,v| self[k.to_s] = deep_parse(v) }
    end
    def deep_parse(data)
      case data
      when Hash
        self.class.new(data)
      when Array
        data.map {|v| deep_parse(v) }
      else
        data
      end
    end
    def method_missing(*args)
      name = args[0].to_s
      return self[name] if has_key? name
      camelname = name.split('_').map {|w| "#{w[0,1].upcase}#{w[1..-1]}" }.join("")
      if has_key? camelname
        self[camelname]
      else
        super *args
      end
    end
  end
  
  
  private # -------------------------------------------------------------------
  
  ##
  # Build search request URL.
  #
  def url(query, page = 0)
    params = {
      :q      => query,
      :alt    => "json"
    }
    uri = Addressable::URI.new
    uri.query_values = params
    begin
      params.merge!(GOOGLE_SEARCH_PARAMS)
    rescue NameError
    end
    "https://www.googleapis.com/customsearch/v1?key=#{GOOGLE_API_KEY}&cx=#{GOOGLE_SEARCH_CX}&#{uri.query}"
  end
  
  ##
  # Query Google, and make sure it responds.
  #
  def fetch(url)
    return HTTParty.get(url)
  end
  
end