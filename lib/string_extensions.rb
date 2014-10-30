class String
  def fix_utf8
    string = self
    string = string.gsub(/\xC5\xA3/, 'ţ')
    string = string.gsub(/\xCE\xBC/, 'μ')
    string = string.gsub(/\xD0\xA1/, 'C')
    string = string.gsub(/\xD0\xB1/, 'б')
    string = string.gsub(/\xD0\xBC/, 'м')
    string = string.gsub(/\xD1\x85/, 'х')

    string = string.gsub(/\xE2\x80\x8E/, '->')
    string = string.gsub(/\xE2\x80\x90/, '‐')
    string = string.gsub(/\xE2\x80\x91/, '‑')
    string = string.gsub(/\xE2\x89\xA4/, '≤')
    string = string.gsub(/\xE2\x97\x8B/, '○')
    string = string.gsub(/\xEF\xAC\x81/, 'ﬁ')
    string = string.gsub(/\xEF\xBD\x87/, 'ｇ')
    string = string.gsub(/\xEF\xBF\xBD/, '�')

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