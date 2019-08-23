module Policr
  @@cache = Hash(String, Time).new
  @@tasks = Hash(String, Proc(Nil)).new

  def self.cached_after(key : String, time : Time::Span, &block)
    @@tasks[key] = block
    return if @@cache[key]?
    @@cache[key] = Time.now + time
    Schedule.after time do
      if task = @@tasks[key]?
        @@tasks.delete key
        task.call
      end
      @@cache.delete key
    end
  end

  def self.cached_after?(key)
    @@cache[key]?
  end

  def self.after(time : Time::Span, &block)
    Schedule.after time, &block
  end

  def self.schedule_immediately(key : String,
                                before = Proc(Nil),
                                after = Proc(Nil),
                                delete : Bool? = true)
    if task = @@tasks[key]?
      @@tasks.delete(key) if delete
      before.call
      task.call
      after.call
    end
  end
end
