require 'json'
require 'net/http'
require 'optparse'
require 'ostruct'

class Resume
  attr_reader :contact, :experience, :skills, :projects, :education

  def initialize(resume)
    @contact = ContactInfo.new(resume['basic_info'])
    @experience = []
    resume['experience'].each do |exp|
      self.experience.push(Experience.new(exp))
    end
    @projects = []
    resume['projects'].each do |proj|
      self.projects.push(Projects.new(proj))
    end
    @skills = Skills.new(resume['skills'])
    @education = []
    resume['education'].each do |edu|
      self.education.push(Education.new(edu))
    end


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

class Experience < ContactInfo

end

class Skills < ContactInfo
  
end

class Projects < ContactInfo
end

class Education < ContactInfo
  attr_accessor :education


end   



class ExistingMethodError < SecurityError
  def initialize(message)
    super(message)
  end
end


# @TODO
# Build linkedin integreation

 

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
  request['Content-Type'] = 'application/json'
  request.basic_auth(options.username, options.password)
  response = http.request(request)
  imported_resume = JSON.parse(response.body)
  resumeImport = Resume.new(imported_resume)
  puts <<EOS
  Contact Info:
  =============
  
EOS
  resumeImport.contact.params.each do |info|
    puts <<EOS
    #{resumeImport.contact.send(info)}
EOS
  end
  puts <<EOS
  
  Projects:
  =========
EOS
  resumeImport.projects.each do |proj|
    puts <<EOS

    #{proj.name} - #{proj.url}
      - #{proj.description}
EOS
  end
  puts <<EOS

  Education:
  ==========
EOS
  resumeImport.education.each do |edu|
  puts <<EOS

    #{edu.course_name} at #{edu.school_name} in #{edu.year}
EOS
  end

  puts <<EOS

  Experience:
  ===========
EOS
  resumeImport.experience.each do |exp|
    if exp.year_ended.nil?
      exp.year_ended = "Current"
    end
    puts <<EOS

    #{exp.job_title} at #{exp.company} from #{exp.year_started} to #{exp.year_ended}
      - #{exp.description}
EOS
  end
  puts <<EOS

  Skills:
  =======
EOS
  resumeImport.skills.params.each do |cat|
    puts <<EOS

    #{cat.capitalize}:

      #{resumeImport.skills.send(cat) * ", "}

EOS
  end

 
end
