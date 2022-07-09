require 'test_helper'

module ActiveStorageOverTime
  class AttachmentTest < ActiveSupport::TestCase

    include Rails.application.routes.url_helpers

    test "valid" do
      attachment = Attachment.new

      attachment.asset = Rack::Test::UploadedFile.new(
        Rails.root.join("../../test/fixtures/blue.png")
      )

      assert_match(
        %r{/rails/active_storage/blobs/(\w+)--(\w+)/(\w+)\.(\w+)\Z},
        polymorphic_path(attachment.asset, only_path: true),
        "Active Storage URL not recognized"
      )

      assert Attachment.new.valid?
    end
  end
end
