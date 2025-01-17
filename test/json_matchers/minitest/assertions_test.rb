require_relative "../../test_helper"
require "active_support/core_ext/string"

class AssertResponseMatchesSchemaTest < JsonMatchers::TestCase
  test "fails with an invalid JSON schema" do
    schema = create(:schema, :invalid)

    json = build(:response)

    assert_raises JsonMatchers::InvalidSchemaError do
      assert_matches_json_schema(json, schema)
    end
  end

  test "does not fail with an empty JSON body" do
    schema = create(:schema, {})

    json = build(:response, {})

    assert_matches_json_schema(json, schema)
  end

  test "fails when the body contains a property with the wrong type" do
    schema = create(:schema, :object)

    json = build(:response, :invalid_object)

    refute_matches_json_schema(json, schema)
  end

  test "fails when the body is missing a required property" do
    schema = create(:schema, :object)

    json = build(:response, {})

    refute_matches_json_schema(json, schema)
  end

  test "when passed a Hash, validates that the schema matches" do
    schema = create(:schema, :object)

    json = build(:response, :object)
    json_as_hash = json.to_h

    assert_matches_json_schema(json_as_hash, schema)
  end

  test "when passed a Hash, fails with message when negated" do
    schema = create(:schema, :object)

    json = build(:response, :invalid_object)
    json_as_hash = json.to_h

    assert_raises_error_containing(schema) do
      assert_matches_json_schema(json_as_hash, schema)
    end
  end

  test "when passed a Array, validates a root-level Array in the JSON" do
    schema = create(:schema, :array_of, :objects)

    json = build(:response, :object)
    json_as_array = [json.to_h]

    assert_matches_json_schema(json_as_array, schema)
  end

  test "when passed a Array, refutes a root-level Array in the JSON" do
    schema = create(:schema, :array_of, :objects)

    json = build(:response, :invalid_object)
    json_as_array = [json.to_h]

    refute_matches_json_schema(json_as_array, schema)
  end

  test "when passed a Array, fails with message when negated" do
    schema = create(:schema, :array_of, :object)

    json = build(:response, :invalid_object)
    json_as_array = [json.to_h]

    assert_raises_error_containing(schema) do
      assert_matches_json_schema(json_as_array, schema)
    end
  end

  test "when JSON is a string, validates that the schema matches" do
    schema = create(:schema, :object)

    json = build(:response, :object)
    json_as_string = json.to_json

    assert_matches_json_schema(json_as_string, schema)
  end

  test "when JSON is a string, fails with message when negated" do
    schema = create(:schema, :object)

    json = build(:response, :invalid_object)
    json_as_string = json.to_json

    assert_raises_error_containing(schema) do
      assert_matches_json_schema(json_as_string, schema)
    end
  end

  test "the failure message contains the body" do
    schema = create(:schema, :object)

    json = build(:response, :invalid_object)

    assert_raises_error_containing(json) do
      assert_matches_json_schema(json, schema)
    end
  end

  test "the failure message contains the schema" do
    schema = create(:schema, :object)

    json = build(:response, :invalid_object)

    assert_raises_error_containing(schema) do
      assert_matches_json_schema(json, schema)
    end
  end

  test "the failure message when negated, contains the body" do
    schema = create(:schema, :object)

    json = build(:response, :object)

    assert_raises_error_containing(json) do
      refute_matches_json_schema(json, schema)
    end
  end

  test "the failure message when negated, contains the schema" do
    schema = create(:schema, :object)

    json = build(:response, :object)

    assert_raises_error_containing(schema) do
      refute_matches_json_schema(json, schema)
    end
  end

  test "asserts valid JSON against a schema that uses $ref" do
    schema = create(:schema, :referencing_objects)

    json = build(:response, :object)
    json_as_array = [json.to_h]

    assert_matches_json_schema(json_as_array, schema)
  end

  test "refutes valid JSON against a schema that uses $ref" do
    schema = create(:schema, :referencing_objects)

    json = build(:response, :invalid_object)
    json_as_array = [json.to_h]

    refute_matches_json_schema(json_as_array, schema)
  end

  def assert_raises_error_containing(schema_or_body)
    raised_error = assert_raises(Minitest::Assertion) do
      yield
    end

    sanitized_message = raised_error.message.squish
    json = JSON.pretty_generate(schema_or_body.to_h)
    error_message = json.squish

    assert_includes sanitized_message, error_message
  end
end
