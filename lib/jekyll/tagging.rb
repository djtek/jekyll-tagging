require 'nuggets/range/quantile'
require 'erb'

module Jekyll

  class TagPage < Page

    def initialize(site, base, dir, tag)
      @site = site
      @base = base
      @dir = dir
      @name = 'index.html'

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'tag_index.html')
      self.data['tag'] = tag

      tag_title_prefix = site.config['tag_title_prefix'] || 'Tag: '
      self.data['title'] = "#{tag_title_prefix}#{tag}"
      self.data['posts'] = site.tags[tag]
    end
  end

  class Tagger < Generator

    safe true
    attr_accessor :site

    def generate(site)
      @site = site
      if site.layouts.key? 'tag_index'
        dir = site.config['tag_dir'] || 'tags'
        site.tags.keys.each do |tag|
          site.pages << TagPage.new(site, site.source, File.join(dir, tag), tag)
        end
        add_tag_cloud
      end
    end

    private
    def add_tag_cloud(num = 5, name = 'tag_data')
      t = { name => calculate_tag_cloud(num) }
      site.respond_to?(:add_payload) ? site.add_payload(t) : site.config.update(t)
    end

    # Calculates the css class of every tag for a tag cloud. The possible
    # classes are: set-1..set-5.
    #
    # [[<TAG>, <CLASS>], ...]
    def calculate_tag_cloud(num = 5)
      range = 0

      tags = active_tags.map { |tag, posts|
        [tag.to_s, range < (size = posts.size) ? range = size : size]
      }


      range = 1..range

      tags.sort!.map! { |tag, size| [tag, range.quantile(size, num)] }
    end

    def active_tags
      return site.tags unless site.config["ignored_tags"]
      site.tags.reject { |t| site.config["ignored_tags"].include? t[0] }
    end

  end

  module TagFilters    
    def tag_cloud(site)
      active_tag_data.map { |tag, set|
        tag_link(tag, tag_url(tag), :class => "set-#{set}")
      }.join(' ')
    end

    def tag_link(tag, url = tag_url(tag), html_opts = nil)
      html_opts &&= ' ' << html_opts.map { |k, v| %Q{#{k}="#{v}"} }.join(' ')
      %Q{<a href="#{url}"#{html_opts}>#{tag}</a>}
    end

    def tag_url(tag)
      File.join('', @context.registers[:site].config["tag_dir"], ERB::Util.u(tag))      
    end

    def tags(obj = nil)
      tags = obj ? obj["tags"]-ignored_tags : active_tags
      tags.map {|e|tag_link(e, tag_url(e), :rel => 'tag')}.join(' ')
    end

    def active_tag_data
      @context.registers[:site].config["tag_data"].reject { |tag, set| ignored_tags.include? tag }
    end
    
    def active_tags
      active_tag_data.map {|e| e[0]}
    end

    def ignored_tags
      @context.registers[:site].config["ignored_tags"]||[]
    end
  end

end
Liquid::Template.register_filter(Jekyll::TagFilters)