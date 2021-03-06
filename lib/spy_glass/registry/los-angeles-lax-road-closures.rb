require 'spy_glass/registry'

opts = {
  path: '/los-angeles-lax-road-closures',
  cache: SpyGlass::Cache::Memory.new(expires_in: 1200),
  source: 'https://data.lacity.org/resource/94t3-k6yn.json?'+Rack::Utils.build_query({
    '$order' => 'lastupdated DESC',
    '$limit' => 100,
    '$where' => <<-WHERE.oneline
        id IS NOT NULL AND
        latitude IS NOT NULL AND
        longitude IS NOT NULL
    WHERE
  })
}

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
  features = collection.map do |item|
    #if Date.parse(item['expireddate']) > Date.today
        title = <<-TITLE.oneline
            #{SpyGlass::Salutations.next} #{item['closuretype']}. #{item['subjecttext']} #{item['bodytext']}
        TITLE

        {
          'id' => item['id'],
          'type' => 'Feature',
          'geometry' => {
            'type' => 'Point',
            'coordinates' => [
              item['longitude'].to_f,
              item['latitude'].to_f
            ]
          },
          'properties' => item.merge('title' => title)
        }
    #end
  end

  {'type' => 'FeatureCollection', 'features' => features}
end
