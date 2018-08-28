require 'tsort'
require 'pika/hash'

module Pika
  class Graph
    include TSort

    def initialize(parent_id: nil, child_id: nil, nodes: nil)
      @parent_id = parent_id
      @child_id = child_id
      @nodes = nodes
    end

    def tsort_each_node(&block)
      @nodes.each(&block)
    end

    def tsort_each_child(leaf, &block)
      @nodes
        .select { |node| Pika::Hash.get(node, @parent_id) == Pika::Hash.get(leaf, @child_id) }
        .each(&block)
    end
  end
end
