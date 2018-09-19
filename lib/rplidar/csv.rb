module Rplidar
  # Dump measurements to CSV file.
  module CSV
    def dump_scans(filename = 'output.csv', iterations = 1)
      responses = scan(iterations)

      file = File.open(filename, 'w')
      file.puts 'start,quality,angle,distance'
      responses.each do |r|
        file.puts "#{r[:start]},#{r[:quality]},#{r[:angle]},#{r[:distance]}"
      end
      file.close
    end
  end
end
