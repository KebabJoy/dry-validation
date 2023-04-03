# frozen_string_literal: true

require "dry/validation/contract"

RSpec.describe Dry::Validation::Contract, "#call" do
  subject(:contract) do
    Class.new(Dry::Validation::Contract) do
      def self.name
        "TestContract"
      end

      params do
        required(:email).filled(:string)
        required(:age).filled(:integer)
        optional(:login).maybe(:string, :filled?)
        optional(:password).maybe(:string, min_size?: 10)
        optional(:password_confirmation).maybe(:string)
        optional(:address).hash do
          required(:country).value(:string)
          required(:zip).value(:string)
          optional(:geolocation).hash do
            required(:lon).value(:float)
            required(:lat).value(:float)
          end
        end
      end

      rule(:login) do
        if key? && (value.length < 3)
          key.failure("too short")
        end
      end

      rule(address: {geolocation: [:lon, :lat]}) do
        if key?
          lon, lat = value
          key("address.geolocation.lat").failure("invalid") if lat < 10
          key("address.geolocation.lon").failure("invalid") if lon < 10
        end
      end

      rule(:password) do
        key.failure("is required") if values[:login] && !values[:password]
      end

      rule(:age) do
        key.failure("must be greater or equal 18") if value < 18
      end

      rule(:age) do
        key.failure("must be greater than 0") if value < 0
      end

      rule(address: :zip) do
        address = values[:address]
        if address && address[:country] == "Russia" && address[:zip] != /\A\d{6}\z/
          key.failure("must have 6 digit")
        end
      end

      rule("address.geolocation.lon") do
        key.failure("invalid longitude") if key? && !(-180.0...180.0).cover?(value)
      end
    end.new
  end

  it "applies rule to input processed by the schema" do
    result = contract.(email: "john@doe.org", age: 19)

    expect(result).to be_success
    expect(result.errors.to_h).to eql({})
  end

  it "applies rule to an optional field when value is present" do
    result = contract.(email: "john@doe.org", age: 19, login: "ab")

    expect(result).to be_failure
    expect(result.errors.to_h).to eql(login: ["too short"], password: ["is required"])
  end

  it "applies rule to an optional nested field when value is present" do
    result = contract.(
      email: "john@doe.org",
      age: 19,
      address: {
        geolocation: {lat: 11, lon: 1},
        country: "Poland",
        zip: "12345"
      }
    )

    expect(result).to be_failure
    expect(result.errors.to_h).to eql(address: {geolocation: {lon: ["invalid"]}})
  end

  it "returns rule errors" do
    result = contract.(email: "john@doe.org", login: "jane", age: 19)

    expect(result).to be_failure
    expect(result.errors.to_h).to eql(password: ["is required"])
  end

  it "doesn't execute rules when basic checks failed" do
    result = contract.(email: "john@doe.org", age: "not-an-integer")

    expect(result).to be_failure
    expect(result.errors.to_h).to eql(age: ["must be an integer"])
  end

  it "gathers errors from multiple rules for the same key" do
    result = contract.(email: "john@doe.org", age: -1)

    expect(result).to be_failure
    expect(result.errors.to_h).to eql(age: ["must be greater or equal 18", "must be greater than 0"])
  end

  it "builds nested message keys for nested rules" do
    result = contract.(email: "john@doe.org", age: 20, address: {country: "Russia", zip: "abc"})

    expect(result).to be_failure
    expect(result.errors.to_h).to eql(address: {zip: ["must have 6 digit"]})
  end

  it "builds deeply nested messages for deeply nested rules" do
    result = contract.(
      email: "john@doe.org",
      age: 20,
      address: {
        country: "UK", zip: "irrelevant",
        geolocation: {lon: "365", lat: "78"}
      }
    )

    expect(result).to be_failure
    expect(result.errors.to_h).to eql(address: {geolocation: {lon: ["invalid longitude"]}})
  end

  context "when input argument is an integer" do
    it "raises a descriptive error" do
      result = -> { contract.(5) }

      expect(&result).to raise_error(ArgumentError, "Input must be a Hash. Integer was given.")
    end
  end

  context "when input argument is an array" do
    it "raises a descriptive error" do
      result = -> { contract.([{name: "Tomas"}]) }

      expect(&result).to raise_error(ArgumentError, "Input must be a Hash. Array was given.")
    end
  end

  context "duplicate key names on nested structures" do
    subject(:contract) do
      Class.new(Dry::Validation::Contract) do
        def self.name
          "RuleTestContract"
        end

        schema do
          required(:data).hash do
            required(:wrapper).hash do
              required(:data).hash do
                required(:id).filled(:string)
              end
            end
          end
        end

        register_macro(:min_size) do |macro:|
          min = macro.args[0]
          key.failure("must have at least #{min} characters") unless value.size >= min
        end

        rule(%i[data wrapper data id]).validate(min_size: 10)
      end.new
    end

    it "only applies the rules to" do
      expected = {data: {wrapper: {data: ["must be a hash"]}}}
      result = contract.(
        data: {
          wrapper: {
            data: []
          }
        }
      )

      expect(result.errors.to_h).to eq(expected)
    end
  end
end
