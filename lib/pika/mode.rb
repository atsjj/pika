module Pika
  class Mode < Enum
    attr_enum :rx, 1
    attr_enum :tx, 2
  end
end
