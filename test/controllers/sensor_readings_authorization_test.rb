require "test_helper"
require "tempfile"

# Cross-tenant isolation for the sensor-readings web actions (not the public
# `transmit` endpoint — that's covered by TransmitControllerTest).
#
# Regression coverage for the pre-fix vulnerabilities:
#   * import/process_file had no authentication at all (unauthenticated
#     cross-tenant write via a project_id param), and
#   * set_project switched current_project from the project_id param with no
#     membership check, so readings/import operated on an arbitrary project.
class SensorReadingsAuthorizationTest < ActionDispatch::IntegrationTest
  test "import requires authentication" do
    assert_no_difference "HygroSensorReading.count" do
      post "/sensor_readings/import", params: { project_id: projects(:one).id }
    end
    assert_redirected_to new_session_path
  end

  test "readings requires authentication" do
    get sensor_readings_url
    assert_redirected_to new_session_path
  end

  test "authenticated import ignores project_id param and writes only to the session project" do
    sign_in users(:two) # owns projects(:two); NOT a member of projects(:one)

    payload = [{
      sensor_id: sensors(:sensor_p2).id,
      temperature: 71, humidity: 42, datetime: "2026-07-13T10:00:00Z"
    }].to_json
    tmp = Tempfile.new(["readings", ".json"])
    tmp.write(payload)
    tmp.rewind
    upload = Rack::Test::UploadedFile.new(tmp.path, "application/json")

    # Even though project_id points at project one, the reading must land in the
    # authenticated user's own project — never the targeted one.
    assert_no_difference -> { projects(:one).hygro_sensor_readings.count } do
      assert_difference -> { projects(:two).hygro_sensor_readings.count }, 1 do
        post "/sensor_readings/import",
             params: { project_id: projects(:one).id, sensor_readings: upload }
      end
    end
  ensure
    tmp&.close
    tmp&.unlink
  end
end
