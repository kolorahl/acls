require 'spec_helper'
require 'acls'

def spec_path(dir)
  "#{Dir.pwd}/spec/#{dir}"
end

def autoload_path(path, opts)
  ACLS::Loader.auto(spec_path(path), opts)
end

def with_modules(modules)
  yield
  mods = modules.map { |mod| mod.split('::').first }.sort.uniq
  mods.each do |mod|
    begin
      Object.send(:remove_const, mod)
    rescue NameError
      # This is ok
    end
  end
end

RSpec::Matchers.define :setup_autoloading_for do |modules|
  description do
    "setup autoloading"
  end

  match do |actual|
    verify(modules, false)
  end

  failure_message do |actual|
    verify(modules, true)
  end

  def verify(modules, with_message)
    modules.each do |name|
      Object.const_get(name).works? or raise NameError.new("incorrect module loaded #{name}")
    end
  rescue NameError => e
    with_message ? e.message : false
  end
end

RSpec::Matchers.define :fail_autoloading_for do |modules|
  description do
    "does not setup autoloading"
  end

  match do |actual|
    verify(modules, false)
  end

  failure_message do |actual|
    verify(modules, true)
  end

  def verify(modules, with_message)
    modules.each do |name|
      begin
        Object.const_get(name).works?
        raise "Should not have loaded #{name}"
      rescue NameError
        # Good
      end
    end
  rescue => e
    with_message ? e.message : false
  end
end

RSpec.describe ACLS::Loader do
  context '#auto' do
    def lib_base_modules
      %w(One Two Sub::Three Sub::Four FIVE Six SevenEight Sub::CamelCase::NineTen)
    end

    def lib_root_modules
      %w(Root::One Root::Two Root::Sub::Three Root::Sub::Four Root::Sub::Five Root::Sub::Six)
    end

    def lib_foo_modules
      %w(Bar::One Bar::Two Bar::Sub::Three Bar::Sub::Four Bar::Sub::Five Bar::Sub::Six)
    end

    def expect_autoloading_for(path, opts, modules)
      with_modules(modules) do
        expect(autoload_path(path, opts)).to setup_autoloading_for(modules)
      end
    end

    def expect_failure_for(path, opts, modules, failures)
      with_modules(modules) do
        expect(autoload_path(path, opts)).to fail_autoloading_for(failures)
      end
    end

    context 'without a root namespace' do
      it { expect_autoloading_for("lib/base", {}, lib_base_modules) }
    end

    context 'with an implicit root namespace' do
      it { expect_autoloading_for("lib/root", {root_ns: true}, lib_root_modules) }
    end

    context 'with a custom root namespace' do
      it { expect_autoloading_for("lib/foo", {root_ns: "Bar"}, lib_foo_modules) }
    end

    context 'with exclusions' do
      it { expect_failure_for("lib/base",
                              {exclude: [/\/sub\//, "two"]},
                              lib_base_modules,
                              %w(Two Sub::Three Sub::Four Sub::CamelCase::NineTen)) }
    end
  end
end
