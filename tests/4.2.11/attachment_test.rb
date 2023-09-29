require 'test_helper'

module ActiveStorageOverTime
  class AttachmentTest < ActiveSupport::TestCase

    include Rails.application.routes.url_helpers

    test "that secret_key_base is correctly set" do
      # That is essential to ensure that the key is correctly generated
      assert_equal(
        Dummy::Application.secret_key_base,
        "your-secret"
      )
    end

    test "that the same message verifier always can decode the token" do
      verifier = ActiveSupport::MessageVerifier.new('foo')

      token = verifier.generate("foo bar")

      assert_equal(
        token,
        "BAhJIgxmb28gYmFyBjoGRVQ=--c96da3d84a4293a81f3a30c71afe1492ec82e9d6"
      )

      assert_equal("foo bar", verifier.verify(token))
    end

    test "the generate_key stay constant" do
      generated_key = "\xF8bssAA?\xCCc\xB4\xD5$&>\x91;\xB1^\xBB'uH\x11 \xED\x8Fi\xF7\xEB\xF2\xC2\xB2\xA0\x94\xD9\xE7\xCD-\xBE\xDDcq,\x8C\xFC\x89\xDDS\x9C\xDFH\n\x8C\x03\x98{\xE4#\x1AR\xA0\xF1\xA4s"

      assert_equal(
        Dummy::Application.key_generator.generate_key("ActiveStorage").force_encoding('UTF-8'),
        generated_key.force_encoding('UTF-8')
      )
    end
  end
end
