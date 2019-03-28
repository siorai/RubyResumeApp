require 'json'
require 'net/http'
require 'optparse'
require 'ostruct'
#require 'prawn'

class Resume
  attr_reader :contact

  def initialize(resume)
    @contact = ContactInfo.new(resume['basic_info'])
    @experience = Experience.new(resume['experience'])

  end

end


# Constructs ContactInfo Object from supplied hash
class ContactInfo
  attr_reader :params, :values


  # Dynamically creates and sets attributes according to the keys passed to it when
  # instantiated. This translates to returning an Object that contains an attribute
  # for every key in the supplied hash with the appropriate value therein.
  #  
  # Because of the potential to overwrite existing methods, accidental or
  # otherwise,  e.g. a 
  #   
  #   "trust" => nil,
  #
  # This constructor will raise an [ExistingMethodError] if it finds any
  # matching existing methods.
  #
  # In the specific example of this object existing as @contact_info
  # as from within the Resume class we can use the following examples:
  #
  # @example Fetch name
  #   
  #   Resume.contact_info.name
  #
  # @example Fetch phone_number
  #
  #   Resume.contact_info.phone_number
  #
  # @param attributes [Hash] Hash from basic_info portion of resume data.
  # @raise [ExistingMethodError] Raise error if key matches existing method
  # @return [Object] Object containing a parameter for each key, value pair 
  def initialize(attributes)
    attributes.each do |attr, value|
      if self.respond_to? attr # Raises error if any keys match existing methods
        raise ExistingMethodError, "Key '#{attr}' matches existing method cannot use."
      end
      define_singleton_method("#{attr}=") { |val| attributes[attr] = val}
      define_singleton_method(attr) { attributes[attr] }
    end
    @params = attributes.keys
    @values = attributes.values
  end

  # Prints all values of 'basic_info' to the terminal
  # @return [Void]
  def print_info
    self.values.each do |value|
      puts value
    end
  end

  
end




# @TODO 
class Experience
  attr_accessor :experience

  # Object containing all the jobs

  def initialize(experience)
    @jobs = []

  end
end   


# @TODO
#class Skills
  # Skills Object - To take 

class ExistingMethodError < SecurityError
  def initialize(message)
    super(message)
  end
end


# console testing
if __FILE__  == $0
  options = OpenStruct.new
  OptionParser.new do |opt|
    opt.on('-s', '--server SERVER URL', 'The server URL') { |o| options.server_url = o}
    opt.on('-u', '--user USERNAME', 'The username given') { |o| options.username = o}
    opt.on('-p', '--password PASSWORD', 'The password for user') { |o| options.password = o}
  end.parse!
  cli_uri = URI(options.server_url)
  http = Net::HTTP.new(cli_uri.host, 443)
  http.use_ssl = true
  request = Net::HTTP::Get.new(cli_uri.request_uri)
  request["Accept"] = "application/json"
  request.basic_auth(options.username, options.password)
  response = http.request(request)
  imported_resume = JSON.parse(response.body)
  resumeImport = Resume.new(imported_resume)
  puts resumeImport   
  resumeImport.contact.params.each do |info|
    puts "Info for #{info} is"
    puts resumeImport.contact.send(info)
  end
 
end

