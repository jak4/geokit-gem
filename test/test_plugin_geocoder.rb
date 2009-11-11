require File.join(File.dirname(__FILE__), 'test_base_geocoder')

Geokit::Geocoders::plugins =  [ {:plugin_name => :yaml,           :model => :yaml_geocoder_plugin,  :find => :find_location, :save => :save_location},
                                {:plugin_name => :always_geocode, :model => :always_geocoder_plugin, :find => :find_location}]
                                

class PluginGeocoderTest < BaseGeocoderTest #:nodoc: all

  def setup
    @geo_loc = Geokit::GeoLoc.new(:city => "Berlin", :street_address => "Mohrenstraße 32")
  end
  
  def teardown
    File.delete(YamlGeocoderPlugin.yml_file) rescue nil
  end
  
  def test_geocoder_plugin_find_fail
    assert !Geokit::Geocoders::PluginGeocoder.geocode(@geo_loc, {:plugin_provider => :yaml}).success
  end
  
  def test_geocoder_plugin_find_success
    assert !Geokit::Geocoders::PluginGeocoder.geocode(@geo_loc, {:plugin_provider => :yaml}).success
    assert Geokit::Geocoders::PluginGeocoder.geocode(@geo_loc, {:plugin_provider => :always_geocode}).success
  end
  
  # this only works with multi-geocoder, because the multi-geocoder calls the PluginGeocoder's save-method
  def test_geocoder_plugin_save
    old_order = Geokit::Geocoders::provider_order
    
    Geokit::Geocoders::provider_order=[:yaml,:always_geocode]
    # this is equivalent to test_geocoder_plugin_find_success
    assert Geokit::Geocoders::MultiGeocoder.geocode(@address).success
    # the yaml_geocoder_plugin now has saved the geocoded address to the yaml file, therefore this has to return a GeoLoc-object with success == true
    assert Geokit::Geocoders::PluginGeocoder.geocode(@geo_loc, {:plugin_provider => :yaml}).success
    
    Geokit::Geocoders::provider_order = old_order
  end
end

# example class for external geocoding
class YamlGeocoderPlugin
  def self.yml_file
    "yaml_geocoder_plugin_store.yml"
  end

  def self.find_location(loc)
    locations = YAML.load_file(yml_file) rescue nil
    
    if locations
      locations.each_pair do |key, value|
        if( value[:street_address].eql?(loc.street_address) and value[:city].eql?(loc.city))
          loc = Geokit::GeoLoc.new(value) 
          loc.success = true
          return loc
        end
      end
    end
    
    return nil
  end
  
  def self.save_location(res)
    locations = YAML.load_file(yml_file) rescue nil
    locations ||= Hash.new
    
    locations["location#{locations.size}"] = res.hash
    File.open(yml_file, 'w') { |f| YAML.dump(locations, f) }
  end
end

class AlwaysGeocoderPlugin
  def self.find_location(loc)
    loc = Geokit::GeoLoc.new(:city => "Berlin", :street_address => "Mohrenstraße 32", :lat => "52.5123417", :lng => "13.3940964")
    loc.success = true
    return loc
  end
end


