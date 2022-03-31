module OAISolr
  class Model < OAI::Provider::Model
    include OAI::Provider

    def earliest
      Time.at(0)
    end

    def latest
      Time.now
    end

    def sets
      nil
    end

    def find(selector, opts={})
      nil
    end
  end
end
