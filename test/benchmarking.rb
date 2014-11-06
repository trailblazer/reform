require 'reform'
require 'ostruct'
require 'benchmark'

class BandForm < Reform::Form
  property :name, validates: {presence: true}

  collection :songs do
    property :title, validates: {presence: true}
  end
end

songs = 50.times.collect { OpenStruct.new(title: "Be Stag") }
band = OpenStruct.new(name: "Teenage Bottlerock", songs: songs)

songs_params = 50.times.collect { {title: "Commando"} }

time = Benchmark.measure do
  100.times.each do
    form = BandForm.new(band)
    form.validate("name" => "Ramones", "songs" => songs_params)
    form.save
  end
end

puts time