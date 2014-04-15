class String
  def fix_utf8
    string = self
    string = string.gsub(/\xD0\xB1/, '-')
    string = string.gsub(/\xE2\x80\x8E/, '-')
    string = string.gsub(/\xE2\x80\x90/, '-')
    string = string.gsub(/\xE2\x97\x8B/, '-')
    string = string.gsub(/\xE2\x80\x91/, '-')
    string = string.gsub(/\xD0\xA1/, '-')
    # string = string.gsub(//, '-')
    return string
  end

  def icecat_datatype
    return "flag" if ["N", "Y"].include? self
    if (( self.to_f.to_s ==  self ) || ( self.to_i.to_s == self )) && self.to_i < 10000000
      return "numeric"
    end
    return "textual"
  end

end