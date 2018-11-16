require 'csv'

class CSVStreamerService
  attr_reader :response, :attachment_name

  def initialize(response, attachment_name)
    @response = response
    @attachment_name = attachment_name
  end

  def send(objects)
    response.headers['Content-Type'] = 'text/csv'
    timestamp = Time.now.strftime('%Y-%m-%d-%H%M%S')
    response.headers['Content-Disposition'] =
      %{attachment; filename="#{attachment_name}-#{timestamp}.csv"}
    response.stream.write(CSV.generate_line(CSVExporter::CSV_COLUMN_HEADINGS))
    objects.each do |object|
      response.stream.write(CSV.generate_line(object.to_csv))
    end
  ensure
    response.stream.close
  end
end
