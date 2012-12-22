# encoding: utf-8

class Court < ActiveRecord::Base
  attr_accessible :uri,
                  :name,
                  :street,
                  :phone,
                  :fax,
                  :media_person,
                  :media_person_unprocessed,
                  :media_phone,
                  :latitude,
                  :longitude
  
  # TODO rm
  #include PgSearch
  #pg_search_scope :search_by_name, against: name, using: :trigram
  
  scope :by_type, lambda { |value| joins(:type).where('value = ?', value) }
 
  belongs_to :type, class_name: :CourtType, foreign_key: :court_type_id
  
  has_many :employments, dependent: :destroy
  
  has_many :judges, through: :employments
  
  has_many :hearings, dependent: :destroy
  has_many :decrees,  dependent: :destroy
  
  belongs_to :jurisdiction, class_name: :CourtJurisdiction
  
  belongs_to :municipality
  
  belongs_to :information_center,       class_name: :CourtOffice, dependent: :destroy
  belongs_to :registry_center,          class_name: :CourtOffice, dependent: :destroy
  belongs_to :business_registry_center, class_name: :CourtOffice, dependent: :destroy
  
  validates :name,   presence: true
  validates :street, presence: true
  
  acts_as_gmappable lat: :latitude, lng: :longitude, process_geocoding: false

  def address(format = '%s, %z %m')
    parts = {
      '%s' => street,
      '%z' => municipality.zipcode,
      '%m' => municipality.name,
      '%c' => 'Slovenská republika'
    }
    
    format.gsub(/\%[szmc]/, parts)
  end

  # TODO rm
  # TODO replace with gem
  def self.similar_by_name(name, similarity)
    result = ActiveRecord::Base.connection.exec_query(<<EOF
    SELECT id, name, similarity(name, '#{name}') as sml 
    FROM courts 
    WHERE name % '#{name}'
    ORDER BY sml DESC, name 
    ;
EOF
    )
    
    result = result.to_hash
    match  = result.first 
    model  = Court.find(match['id'])
    
    return model if match['sml'].to_f >= similarity
  end
end
