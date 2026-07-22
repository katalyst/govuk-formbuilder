# frozen_string_literal: true

# A direct-uploads endpoint that holds each request until the test releases
# it, so system tests can observe the transient uploading state and decide
# how the request resolves: release with :ok to proceed normally, or with an
# HTTP status (symbol or integer) to respond with that status instead. The
# hold times out rather than hang the suite if a test forgets to release.
class BlockingDirectUploadsController < ActiveStorage::DirectUploadsController
  QUEUE = Queue.new

  # Allows one held request to proceed.
  def self.release(result = :ok)
    QUEUE << result
  end

  def create
    result = QUEUE.pop(timeout: 5)

    if result.nil? || result == :ok
      super
    else
      head result
    end
  end
end
