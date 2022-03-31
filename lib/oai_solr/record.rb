module OAISolr
  class Record
    def self.earliest
      Time.at(0)
    end

    def self.latest
      Time.now
    end
  end
end
