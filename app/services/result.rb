class Result
  attr_reader :success, :data, :error

  def initialize(success, data = nil, error = nil)
    @success = success
    @data = data
    @error = error
  end

  def success?
    @success
  end

  def failure?
    !@success
  end

  def self.success(data = nil)
    new(true, data, nil)
  end

  def self.failure(error = nil)
    new(false, nil, error)
  end
end
