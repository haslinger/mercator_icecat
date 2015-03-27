class String

  def fix_icecat
    self.gsub("\\n", "")
  end

  def icecat_datatype
    return "flag" if ["N", "Y"].include? self
    if (( self.to_f.to_s ==  self ) || ( self.to_i.to_s == self )) && self.to_i < 10000000
      return "numeric"
    end
    return "textual"
  end
end