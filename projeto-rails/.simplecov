SimpleCov.start "rails" do
  track_files "app/controllers/**/*.rb"
  track_files "app/models/**/*.rb"

  minimum_coverage_by_group(
    "Controllers" => 90.00,
    "Models" => 90.00
  )
end