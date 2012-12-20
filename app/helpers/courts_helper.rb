# encoding: utf-8

module CourtsHelper
  def court_email(court, separator = ', ')
    court.email.split(/,\s+/).map { |email| mail_to email, nil, encode: :hex }.join(separator).html_safe
  end

  # TODO implement
  def court_phone(court, separator = ', ')
    court.phone
  end
  
  def court_map(court, options = {})
    courts_map [court], options
  end
  
  def court_map_direction(court, options = {})
    options = courts_map_defaults.merge options
    "https://maps.google.sk/maps?&t=m&z=#{options[:zoom]}&daddr=#{court.address}, Slovenská republika"
  end
  
  def courts_map(courts, options = {})
    options = courts_map_defaults.merge options
    id      = "map_#{'court'.pluralize(courts.count)}_#{courts.hash.abs}"
    data    = {
      map_options: {
        container_class: :map,
        class: :view,
        id: id,
        
        auto_adjust: true,
        auto_zoom: false,
        zoom: options[:zoom],
        
        raw: "{ disableDefaultUI: #{!options[:ui]} }",
        
        language: :sk,
        region: :sk,
        hl: :sk
      },
      
      markers: {
        data: courts_map_markers(courts, options)
      }
    }
    
    map = gmaps(data)
    
    if options[:info]
      content_for :scripts do
        content_tag :script, type: 'text/javascript', charset: 'utf-8' do
          render partial: 'map_marker_info.js', locals: { id: id }
        end
      end
    end
    
    map
  end
  
  def link_to_court(court)
    link_to court.name, court_path(court.id)
  end
  
  private
  
  def courts_map_defaults
    {
      info: false,
      zoom: 7,
      ui: true
    }
  end
  
  def courts_map_markers(courts, options)
    groups = {}
    marked = []
    
    courts.each do |court|
      coordinates = "#{court.latitude},#{court.longitude}"
      
      marked << court if groups[coordinates].nil?
      
      groups[coordinates] ||= []
      groups[coordinates] << court
    end
    
    marked.to_gmaps4rails do |court, marker|
      coordinates = "#{court.latitude},#{court.longitude}"
      marker.infowindow render partial: 'map_marker_info.html', locals: { courts: groups[coordinates] }
    end
  end
end
