module PoiServices
  class PoiOptimizedSerializer
    CACHE_KEY_PREFIX = "json_cache/#{Poi.model_name.cache_key}".freeze
    CACHE_KEY_FORMAT = "#{CACHE_KEY_PREFIX}/%d-%d".freeze

    def initialize(pois_scope, box_size:, &serializer)
      @pois = pois_scope
      @box_size = box_size.to_f
      @serializer = serializer
    end

    def serialize
      pois_metadata = @pois.pluck(with_clustering(:id, :updated_at))

      return [] if pois_metadata.empty?

      cache_keys_by_id = {}
      pois_metadata.each do |id, timestamp|
        cache_keys_by_id[id] = CACHE_KEY_FORMAT % [id, timestamp.utc.to_s(:nsec)]
      end

      cached_values = $redis.mget(*cache_keys_by_id.values)

      ids = pois_metadata.map(&:first)
      pois_by_id = {}
      ids_to_fetch_from_database = []

      ids.zip(cached_values).each do |id, cached_value|
        if cached_value != nil
          pois_by_id[id] = cached_value
        else
          ids_to_fetch_from_database.push(id)
        end
      end

      if ids_to_fetch_from_database.any?
        pois_from_database = Poi.where(id: ids_to_fetch_from_database)
        cache_writes = []

        @serializer.call(pois_from_database).each do |poi|
          json = poi.to_json
          pois_by_id[poi[:id]] = json
          cache_writes.push(cache_keys_by_id[poi[:id]], json)
        end

        $redis.mset(*cache_writes)
      end

      ids.map { |id| SerializedJSON.new(pois_by_id[id]) }
    end

    private
    # Divides the area in a grid of squares and keep only one POI per square
    def with_clustering *projections
      if @box_size >= 10
        grid_size = @box_size / 15
      elsif @box_size >= 5
        grid_size = @box_size / 30
      else
        # no clustering
        return projections.join(", ")
      end

      %(
        distinct on (
          ST_SnapToGrid(
            ST_Transform(
              ST_SetSRID(
                ST_MakePoint(longitude, latitude),
                4326),
              3785),
            #{grid_size * 1000})
        )
        #{projections.join(", ")}
      )
    end

    # wraps a JSON fragment to prevent the encoder to re-serialize it
    class SerializedJSON < BasicObject
      def initialize(json)
        @json = json
      end

      def as_json *args
        self
      end

      def to_json *args
        @json
      end
    end

    # patches the JSON encoder to handle pre-serialized fragments
    module EncoderMixin
      private
      def jsonify(value)
        case value
        when SerializedJSON
          value
        else
          super
        end
      end
    end

    ActiveSupport.json_encoder.prepend(EncoderMixin)

    def self.clear_cache
      $redis.del($redis.keys("#{CACHE_KEY_PREFIX}/*"))
    end
  end
end
