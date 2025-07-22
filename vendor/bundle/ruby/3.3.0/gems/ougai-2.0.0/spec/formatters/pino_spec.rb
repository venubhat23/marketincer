require 'spec_helper'

describe Ougai::Formatters::Pino do
  let(:data) do
    {
      msg: 'Log Message!',
      status: 200,
      method: 'GET',
      path: '/'
    }
  end

  let(:stack) { "error1.rb\n    error2.rb" }

  let(:err) do
    {
      name: 'DummyError',
      message: 'it is dummy.',
      stack: stack
    }
  end

  let(:formatter) { described_class.new }

  include_examples 'formatter#initialize',
    default_opts: {
      trace_indent: 4,
      trace_max_lines: 100,
      serialize_backtrace: true,
      jsonize: true,
      with_newline: true
    },
    options: {
      jsonize: false,
      with_newline: false
    }

  describe '#call' do
    let!(:time_epoc_msec) { 1518710101026 }

    before { Timecop.freeze(Time.at(time_epoc_msec / 1000.0)) }
    after { Timecop.return }

    subject { formatter.call(severity, Time.now, nil, data) }

    context 'jsonize is true and with_newline is true' do
      let!(:severity) { 'DEBUG' }

      it 'includes valid strings' do
        expect(subject).to end_with("\n")
        result = JSON.parse(subject.chomp, symbolize_names: true)
        expect(result).to include(data.merge(pid: $$, level: 20, time: time_epoc_msec, v: 1))
      end
    end

    context 'jsonize is false' do
      let!(:time) { Time.at(time_epoc_msec / 1000.0) }

      before do
        formatter.jsonize = false
      end

      context 'when severity is TRACE' do
        let!(:severity) { 'TRACE' }

        it 'includes valid hash' do
          expect(subject).to include(data.merge(pid: $$, level: 10, time: time, v: 1))
        end
      end

      context 'when severity is DEBUG' do
        let!(:severity) { 'DEBUG' }

        it 'includes valid hash' do
          expect(subject).to include(data.merge(pid: $$, level: 20, time: time, v: 1))
        end
      end

      context 'when severity is INFO' do
        let!(:severity) { 'INFO' }

        it 'includes valid hash' do
          expect(subject).to include(data.merge(pid: $$, level: 30, time: time, v: 1))
        end
      end

      context 'when severity is WARN' do
        let!(:severity) { 'WARN' }

        it 'includes valid hash' do
          expect(subject).to include(data.merge(pid: $$, level: 40, time: time, v: 1))
        end
      end

      context 'when severity is ERROR' do
        let!(:severity) { 'ERROR' }

        before do
          data.delete(:msg)
          data.merge!({ err: err })
        end

        it 'includes valid hash' do
          expect(subject).to include({
            pid: $$, level: 50, time: time, v: 1,
            type: 'Error',
            msg: 'it is dummy.',
            stack: "DummyError: it is dummy.\n    #{stack}"
          })
        end
      end

      context 'when severity is FATAL and trace_indent = 2' do
        let!(:severity) { 'FATAL' }

        let!(:data) do
          { msg: 'TheEnd', err: err }
        end

        before do
          formatter.trace_indent = 2
          stack.gsub!(/    /, '  ')
        end

        it 'includes valid hash' do
          expect(subject).to include({
            pid: $$, level: 60, time: time, v: 1,
            type: 'Error',
            msg: 'TheEnd',
            stack: "DummyError: it is dummy.\n  #{stack}",
          })
        end
      end

      context 'when severity is UNKNOWN' do
        let!(:severity) { 'ANY' }

        let!(:data) do
          { msg: 'unknown msg' }
        end

        it 'includes valid hash' do
          expect(subject).to include(pid: $$, level: 70, time: time, msg: 'unknown msg')
        end
      end
    end

    context 'with_newline is false' do
      let!(:severity) { 'INFO' }

      before do
        formatter.with_newline = false
      end

      it 'includes valid strings' do
        expect(subject).not_to end_with("\n")
        result = JSON.parse(subject, symbolize_names: true)
        expect(result).to include(data.merge(level: 30, time: time_epoc_msec))
      end
    end
  end

  describe '#datetime_format' do
    it 'is not supported' do
      expect{ formatter.datetime_format = '%I:%M:%S %p' }.to raise_error(NotImplementedError)
    end
  end
end
