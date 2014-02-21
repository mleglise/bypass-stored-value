class Hash
  def all_values_for_key(key)
    result = []
    result << self[key]
    self.values.each do |hash_value|
      values = [hash_value] unless hash_value.is_a? Array
      values.each do |value|
        result += value.all_values_for_key(key) if value.is_a? Hash
      end
    end
    result.compact
  end

  def value_for_key(key)
    find_all_values_for_key(key).try(:first) || []
  end
end
