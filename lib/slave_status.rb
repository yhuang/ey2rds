require 'json'

class SlaveStatus
  def initialize(lines)
    @data = {}

    lines.each do |line|
      key, value = line.chomp.split(/: /)
      next unless value

      @data[key.strip] = numeric?(value) ? value.to_i : value
    end
  end

  def to_s
    @data.to_json
  end

  private

  def numeric?(value)
    Float(value) rescue false
  end
end