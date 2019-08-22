module Policr
  @@cache = Hash(String, Time).new

  def self.cached_after(key : String, time : Time::Span, &block)
    return if @@cache[key]?
    @@cache[key] = Time.now + time
    Schedule.after time do
      block.call
      @@cache.delete key
    end
  end

  def self.cached_after?(key)
    @@cache[key]?
  end

  def self.after(time : Time::Span, &block)
    Schedule.after time, &block
  end
end
