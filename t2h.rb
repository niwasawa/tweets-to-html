require 'twitter_api'
require 'json'
require 'cgi'
require 'erb'
require 'optparse'

module TweetsToHtml

  class Tweets

    def initialize()
    end

    def to_html(params)

      t = TwitterAPI::Client.new(params.auth)

      res = t.statuses_user_timeline({
        'screen_name' => params.screen_name,
        'count' => params.count,
        'tweet_mode' => 'extended'
      })

      statuses = JSON.parse(res.body)

      tweets = []
      statuses.each do |status|
        t = {
          'status' => status,
          'body' => create_body(status),
          'images' => create_images(status, params),
          'time' => create_time(status),
          'url' => create_url(status)
        }
        tweets.unshift(t)
      end

      erb = ERB.new(params.template)
      puts erb.result(binding)
    end

    private

    def create_body(status)
      if status['retweeted_status']
        body = CGI.escapeHTML("RT @#{status['retweeted_status']['user']['screen_name']}\n#{status['retweeted_status']['full_text']}")
      else
        body = CGI.escapeHTML(status['full_text'])
      end
      body = body.gsub(/\n/, '<br>')
      body = body.gsub(/ /, '&nbsp;')
    end

    def create_images(status, params)

      if ['thumb', 'small', 'medium', 'large'].include?(params.image_size)
        image_size = params.image_size
        long_edge_length = nil
      else
        image_size = 'large'
        long_edge_length = params.image_size.to_i
      end
      
      images = []
      if status['entities'] && status['entities']['media']
        status['entities']['media'].each do |media|
          w = media['sizes'][image_size]['w']
          h = media['sizes'][image_size]['h']
          if long_edge_length != nil
            wh = adjust_length(w.to_i, h.to_i, long_edge_length)
            w = wh['w']
            h = wh['h']
          end
          images << {
            'src'    => media['media_url_https'],
            'width'  => w,
            'height' => h,
            'link'   => media['expanded_url']
          }
        end
      end
      images
    end

    def create_time(status)
      time = Time.parse(status['created_at'])
      time = time.getlocal('+09:00') # JST: Japan Standard Time
      str = time.strftime('%F %T') # %F %T = %Y-%m-%d %H:%M:%S
      CGI.escapeHTML(str)
    end

    def create_url(status)
      CGI.escapeHTML("https://twitter.com/#{status['user']['screen_name']}/status/#{status['id_str' ]}")
    end

    def adjust_length(w, h, long_edge_length)
      long_edge = [w, h].max
      r = Rational(long_edge_length, long_edge)
      {'w' => (r * w).round(), 'h' => (r * h).round()}
    end

  end

  class Parameters

    attr_reader :screen_name, :count, :image_size

    def initialize(argv)
      result = {}
      opt = OptionParser.new()
      @auth_file = 'auth.json'
      @template_file = 'template.erb'
      @count = 200
      @image_size = 'small'
      opt.on('--auth=auth.json', 'the auth JSON file')            {|v| @auth_file   = v}
      opt.on('--template=template.erb', 'the template file')      {|v| @template_file = v}
      opt.on('--name=screen_name', 'the screen_name of the user') {|v| @screen_name = v}
      opt.on('--count=200', 'the number of tweets')               {|v| @count = v}
      opt.on('--image-size=small', 'thumb, small, medium, large or 640 and so (the length of the long edge)') {|v| @image_size = v}
      opt.parse(argv)
    end

    def auth()
      JSON.parse(File.read(@auth_file), {:symbolize_names => true})
    end

    def template()
      File.read(@template_file)
    end

  end

end

# main
p = TweetsToHtml::Parameters.new(ARGV)
TweetsToHtml::Tweets.new().to_html(p)

