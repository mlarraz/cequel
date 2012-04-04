module Cequel

  class Keyspace

    include Helpers

    #
    # @api private
    # @see Cequel.connect
    #
    def initialize(connection)
      @connection = connection
    end

    #
    # Get DataSet encapsulating a column group in this keyspace
    #
    # @param column_group_name [Symbol] the name of the column group
    # @return [DataSet] a column group
    #
    def [](column_group_name)
      DataSet.new(column_group_name.to_sym, self)
    end

    #
    # Execute a CQL query in this keyspace.
    #
    # @param statement [String] CQL string
    # @param *bind_vars [Object] values for bind variables
    #
    def execute(statement, *bind_vars)
      @connection.execute(statement, *bind_vars)
    end

    #
    # Write data to this keyspace using a CQL query. Will be included the
    # current batch operation if one is present.
    #
    # @param (see #execute)
    #
    def write(statement, *bind_vars)
      if @batch
        @batch.execute(sanitize(statement, *bind_vars))
      else
        execute(statement, *bind_vars)
      end
    end

    #
    # Execute write operations in a batch. Any inserts, updates, and deletes
    # inside this method's block will be executed inside a CQL BATCH operation.
    #
    # @param options [Hash]
    # @option options [Fixnum] :auto_apply Automatically send batch to Cassandra after this many statements
    #
    # @example Perform inserts in a batch
    #   DB.batch do
    #     DB[:posts].insert(:id => 1, :title => 'One')
    #     DB[:posts].insert(:id => 2, :title => 'Two')
    #   end
    #
    def batch(options = {})
      old_batch, @batch = @batch, Batch.new(self, options)
      yield
      @batch.apply
    ensure
      @batch = old_batch
    end

  end

end
