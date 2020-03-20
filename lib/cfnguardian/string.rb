class String
  include Term::ANSIColor
  
  def to_underscore
    self.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  end
  
  def to_camelcase
    self.split('_').collect(&:capitalize).join
  end
  
  def to_resource_name
    self.split(/(\.|-|_)/).
    map(&:capitalize).join.
    gsub(/[^0-9A-Za-z]/, '')
  end
  
  def to_heading
    self.split('_').collect(&:capitalize).join(' ')
  end
  
  def word_wrap(with=100)
    self.scan(/\S.{0,#{with}}\S(?=\s|$)|\S+/).
    map {|line| line + "\n"}.
    join('')
  end
end