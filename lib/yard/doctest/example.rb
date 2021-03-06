module YARD
  module Doctest
    class Example < ::Minitest::Spec

      # @return [String] namespace path of example (e.g. `Foo#bar`)
      attr_accessor :definition

      # @return [String] filepath to definition (e.g. `app/app.rb:10`)
      attr_accessor :filepath

      # @return [Array<Hash>] assertions to be done
      attr_accessor :asserts

      #
      # Generates a spec and registers it to Minitest runner.
      #
      def generate
        this = self

        Class.new(this.class).class_eval do
          require 'minitest/autorun'

          %w[. support].each do |dir|
            require "#{dir}/doctest_helper" if File.exist?("#{dir}/doctest_helper.rb")
          end

          return if YARD::Doctest.skips.any? { |skip| this.definition.include?(skip) }
          describe this.definition do
            register_hooks(this.definition, YARD::Doctest.hooks)

            it this.name do
              this.asserts.each do |assert|
                expected, actual = assert[:expected], assert[:actual]
                next if expected.empty?

                begin
                  assert_equal evaluate(expected), evaluate(actual)
                rescue Minitest::Assertion => error
                  add_filepath_to_backtrace(error, this.filepath)
                  raise error
                end
              end
            end
          end
        end
      end

      protected

      def evaluate(code)
        context.eval(code)
      rescue StandardError => error
        "#<#{error.class}: #{error}>"
      end

      def context
        @binding ||= binding
      end

      def add_filepath_to_backtrace(exception, filepath)
        backtrace = exception.backtrace
        line = backtrace.find { |l| l =~ %r{lib/yard/doctest/example} }
        index = backtrace.index(line)
        backtrace = backtrace.insert(index, filepath)
        exception.set_backtrace backtrace
      end

      def self.register_hooks(definition, all_hooks)
        all_hooks.each do |type, hooks|
          hooks.each do |hook|
            if hook[:test]
              # test-name hooks
              send(type, &hook[:block]) if definition.include?(hook[:test])
            else
              # global hooks
              send(type, &hook[:block])
            end
          end
        end
      end

    end # Example
  end # Doctest
end # YARD
