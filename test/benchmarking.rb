require "reform"
require "benchmark/ips"
require "reform/form/dry"

class BandForm < Reform::Form
  feature Reform::Form::Dry
  property :name #, validates: {presence: true}
  collection :songs do
    property :title #, validates: {presence: true}
  end
end

class OptimizedBandForm < Reform::Form
  feature Reform::Form::Dry
  property :name #, validates: {presence: true}
  collection :songs do
    property :title #, validates: {presence: true}

  	def deserializer(*args)
      # DISCUSS: should we simply delegate to class and sort out memoizing there?
      self.class.deserializer_class || self.class.deserializer_class = deserializer!(*args)
  	end
  end

  def deserializer(*args)
    # DISCUSS: should we simply delegate to class and sort out memoizing there?
    self.class.deserializer_class || self.class.deserializer_class = deserializer!(*args)
  end
end

songs = 10.times.collect { OpenStruct.new(title: "Be Stag") }
band = OpenStruct.new(name: "Teenage Bottlerock", songs: songs)

unoptimized_form = BandForm.new(band)
optimized_form   = OptimizedBandForm.new(band)

songs_params = songs_params = 10.times.collect { {title: "Commando"} }

Benchmark.ips do |x|
   x.report("2.2") { BandForm.new(band).validate("name" => "Ramones", "songs" => songs_params) }
   x.report("2.3") { OptimizedBandForm.new(band).validate("name" => "Ramones", "songs" => songs_params)  }
end

exit

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
