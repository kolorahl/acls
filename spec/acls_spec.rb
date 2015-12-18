require 'spec_helper'
require 'acls'

def spec_path(dir)
  "#{Dir.pwd}/spec/#{dir}"
end

def autoload_path(path, opts)
  ACLS::Loader.auto(spec_path(path), opts)
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
      expect(autoload_path(path, opts)).to setup_autoloading_for(modules)
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
  end
end
