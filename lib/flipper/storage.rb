require "flipper/adapter"

module Flipper
  class Storage
    def initialize(adapter)
      @adapter = adapter
    end

    def features
      case @adapter.version
      when Adapter::V1
        @adapter.features
      when Adapter::V2
        v2_features
      end
    end

    def get(feature)
      case @adapter.version
      when Adapter::V1
        @adapter.get(feature)
      when Adapter::V2
        if raw = @adapter.get("feature/#{feature.key}")
          Marshal.load(raw)
        else
          v2_default_gate_values
        end
      end
    end

    def enable(feature, gate, thing)
      case @adapter.version
      when Adapter::V1
        @adapter.add feature
        @adapter.enable feature, gate, thing
      when Adapter::V2
        v2_add_feature(feature)
        hash = get(feature)
        case gate.data_type
        when :boolean, :integer
          hash[gate.key] = thing.value
        when :set
          hash[gate.key].add(thing.value)
        end
        @adapter.set("feature/#{feature.key}", Marshal.dump(hash))
      end
    end

    def disable(feature, gate, thing)
      case @adapter.version
      when Adapter::V1
        @adapter.add feature
        if gate.is_a?(Gates::Boolean)
          @adapter.clear feature
        else
          @adapter.disable feature, gate, thing
        end
      when Adapter::V2
        v2_add_feature(feature)
        hash = get(feature)
        case gate.data_type
        when :boolean
          hash = v2_default_gate_values
        when :integer
          hash[gate.key] = thing.value
        when :set
          hash[gate.key].delete(thing.value)
        end
        @adapter.set("feature/#{feature.key}", Marshal.dump(hash))
      end
    end

    def remove(feature)
      case @adapter.version
      when Adapter::V1
        @adapter.remove(feature)
      when Adapter::V2
        set = v2_features
        if set.include?(feature.key)
          set.remove(feature.key)
          @adapter.set("features", Marshal.dump(set))
        end
      end
    end

    private

    def v2_default_gate_values
      {
        :boolean => nil,
        :groups => Set.new,
        :actors => Set.new,
        :percentage_of_actors => nil,
        :percentage_of_time => nil,
      }
    end

    def v2_add_feature(feature)
      set = v2_features
      unless set.include?(feature.key)
        set.add(feature.key)
        @adapter.set("features", Marshal.dump(set))
      end
    end

    def v2_features
      if raw = @adapter.get("features")
        Marshal.load(raw)
      else
        Set.new
      end
    end
  end
end