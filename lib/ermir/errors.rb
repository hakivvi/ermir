# frozen_string_literal: true
module Ermir
  module Errors
    FILE_PATH_ERROR = "the file path specified is not valid."
    FILE_CORRUPTED_ERROR = "the serialized object in the specified file has a corrupted header."
    STDIN_EMPTY_ERROR = "pipe mode was selected, but STDIN is found empty."
    STDIN_CORRUPTED_ERROR = "the piped serialized object has a corrupted header."
    GADGET_NOT_PROVIDED = "provide at least one source for the serialized gadget (--file) or (--pipe)."
  end
end