require 'json'

class Parameters
  def initialize(params)
    input   = params[:input]
    @data   = load_defaults params[:stack_name]

    if input
      parameters = input[0].gsub(/\s+/, "").split(/;/)

      parameters.each do |parameter|
        key, value = parameter.chomp.split(/\=/)
        next unless value

        @data[key.strip] = numeric?(value) ? value.to_i : value
      end

      if params[:action] == 'update'
        @data['SnapshotId'] = 'UsePreviousValue'
      end
    end
  end

  def to_s
    serialize(@data).to_json
  end

  private

  def numeric?(value)
    Float(value) rescue false
  end

  def load_defaults(stack_name)
    env, app, role, stack_number = stack_name.split(/-/)
    match_data = stack_number.match /^s(\d+)/
    defaults = {
      'StackNumber' => match_data[1]
    }
    JSON.parse(File.read "config/#{env}-#{app}-mysql.json").each do |hash|
      defaults[hash['ParameterKey']] = hash['ParameterValue']
    end
    defaults
  end

  def serialize(hash)
    parameters = []
    hash.each do |key, value|
      if value == 'UsePreviousValue'
        parameters << "ParameterKey=#{key},UsePreviousValue=true"
      else
        parameters << "ParameterKey=#{key},ParameterValue=#{value}"
      end
    end
    parameters.join(' ')
  end
end