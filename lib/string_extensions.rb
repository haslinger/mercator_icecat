class String

  def fix_icecat
    self.fix_utf8.gsub!("\\n", "")
  end

  def fix_utf8
    string = self
    string = string.gsub(/\xC4\xB1/, 'i')
    string = string.gsub(/\xC5\xA3/, 't')
    string = string.gsub(/\xCE\xBC/, 'm')
    string = string.gsub(/\xD0\xA1/, 'c')
    string = string.gsub(/\xD0\xB1/, 's')
    string = string.gsub(/\xD0\xBC/, 'm')
    string = string.gsub(/\xD1\x85/, 'x')



    string = string.gsub(/\xE2\x80\x8E/, '->')
    string = string.gsub(/\xE2\x80\x90/, '-')
    string = string.gsub(/\xE2\x80\x91/, '-')
    string = string.gsub(/\xE2\x89\xA4/, '<=')
    string = string.gsub(/\xE2\x97\x8B/, 'o')
    string = string.gsub(/\xEF\xAC\x81/, 'f')
    string = string.gsub(/\xEF\xBD\x87/, 'g')
    string = string.gsub(/\xEF\xBF\xBD/, '?')

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